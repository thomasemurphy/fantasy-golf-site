class SyncTournamentResultsJob < ApplicationJob
  queue_as :default

  def perform(tournament_id = nil)
    tournament = if tournament_id
      Tournament.find(tournament_id)
    else
      Tournament.where(status: %w[in_progress completed])
                .order(end_date: :desc)
                .first
    end

    unless tournament
      Rails.logger.info "[SyncTournamentResultsJob] No tournament to sync"
      return
    end

    data = EspnGolf.new.current_leaderboard

    unless data
      Rails.logger.warn "[SyncTournamentResultsJob] No active ESPN event returned"
      return
    end

    # Sanity-check: verify ESPN is returning data for this tournament
    unless data[:event_name].to_s.downcase.include?(tournament.name.split.last.downcase)
      Rails.logger.warn "[SyncTournamentResultsJob] ESPN event '#{data[:event_name]}' " \
                        "does not match tournament '#{tournament.name}' — skipping"
      return
    end

    players = data[:players]

    ApplicationRecord.transaction do
      players.each do |p|
        golfer = find_or_create_golfer(p[:name])
        next unless golfer

        result = TournamentResult.find_or_initialize_by(tournament: tournament, golfer: golfer)
        result.assign_attributes(
          current_position:         p[:rank],
          current_position_display: p[:position_display],
          current_score_to_par:     p[:score_to_par],
          current_thru:             p[:thru],
          current_round:            p[:current_round],
          made_cut:                 p[:made_cut]
        )
        result.save!
      end

      # Project earnings based on current position and tournament purse.
      project_earnings(tournament)

      # Sync made_cut onto picks so no-cut challenge tracking is accurate.
      # Earnings are entered separately via the admin earnings form.
      tournament.picks.each do |pick|
        result = TournamentResult.find_by(tournament: tournament, golfer: pick.golfer)
        next unless result
        pick.update_column(:made_cut, result.made_cut)
      end

      if data[:completed] && tournament.status == "in_progress" && Time.current >= tournament.end_date.end_of_day
        tournament.update!(status: "completed")
        just_completed = true
        Rails.logger.info "[SyncTournamentResultsJob] Marked #{tournament.name} as completed"
      end
    end

    if just_completed
      if tournament.pgatour_id.present?
        SyncTournamentEarningsJob.perform_later(tournament.id)
        Rails.logger.info "[SyncTournamentResultsJob] Enqueued SyncTournamentEarningsJob for #{tournament.name}"
      else
        Rails.logger.warn "[SyncTournamentResultsJob] #{tournament.name} completed but has no pgatour_id — skipping earnings sync"
      end
    end

    Rails.logger.info "[SyncTournamentResultsJob] Synced results for #{tournament.name} (#{players.size} players)"
  end

  private

  def find_or_create_golfer(espn_name)
    find_golfer(espn_name) || Golfer.create!(name: espn_name)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "[SyncTournamentResultsJob] Could not create golfer '#{espn_name}': #{e.message}"
    nil
  end

  def find_golfer(espn_name)
    return Golfer.find_by(name: espn_name) if Golfer.exists?(name: espn_name)

    normalized = espn_name.gsub(".", "").squeeze(" ").strip
    return Golfer.find_by(name: normalized) if Golfer.exists?(name: normalized)

    # Try accent-stripped comparison (e.g. "Højgaard" → "Hojgaard")
    stripped = strip_accents(espn_name)
    Golfer.all.each do |g|
      return g if strip_accents(g.name) == stripped
    end

    last_name = espn_name.split.last
    matches   = Golfer.where("name ILIKE ?", "%#{last_name}")
    matches.first if matches.one?
  end

  # Standard PGA Tour payout percentages by finishing position (sums to 100%).
  PAYOUT_PERCENTAGES = {
     1 => 18.000,  2 => 10.900,  3 =>  6.900,  4 =>  4.900,  5 =>  4.100,
     6 =>  3.625,  7 =>  3.375,  8 =>  3.125,  9 =>  2.925, 10 =>  2.725,
    11 =>  2.525, 12 =>  2.325, 13 =>  2.125, 14 =>  1.925, 15 =>  1.825,
    16 =>  1.725, 17 =>  1.625, 18 =>  1.525, 19 =>  1.425, 20 =>  1.325,
    21 =>  1.225, 22 =>  1.125, 23 =>  1.045, 24 =>  0.965, 25 =>  0.885,
    26 =>  0.805, 27 =>  0.775, 28 =>  0.745, 29 =>  0.715, 30 =>  0.685,
    31 =>  0.655, 32 =>  0.625, 33 =>  0.595, 34 =>  0.570, 35 =>  0.545,
    36 =>  0.520, 37 =>  0.495, 38 =>  0.475, 39 =>  0.455, 40 =>  0.435,
    41 =>  0.415, 42 =>  0.395, 43 =>  0.375, 44 =>  0.355, 45 =>  0.335,
    46 =>  0.315, 47 =>  0.295, 48 =>  0.279, 49 =>  0.265, 50 =>  0.257,
    51 =>  0.251, 52 =>  0.245, 53 =>  0.241, 54 =>  0.237, 55 =>  0.235,
    56 =>  0.233, 57 =>  0.231, 58 =>  0.229, 59 =>  0.227, 60 =>  0.225,
    61 =>  0.223, 62 =>  0.221, 63 =>  0.219, 64 =>  0.217, 65 =>  0.215
  }.freeze

  def project_earnings(tournament)
    purse = tournament.purse_cents.to_i
    return if purse.zero?

    results = TournamentResult.where(tournament: tournament).to_a

    # Group made-cut players by numeric position to handle ties correctly.
    # Tied players split the sum of prize money for the positions they occupy.
    results.select { |r| r.made_cut? && r.current_position }
           .group_by(&:current_position)
           .each do |position, tied_results|
             size = tied_results.size
             total_pct = (position...position + size).sum { |p| PAYOUT_PERCENTAGES[p] || 0.0 }
             earnings = (purse * total_pct / 100.0 / size).round
             TournamentResult.where(id: tied_results.map(&:id))
                             .update_all(current_earnings_cents: earnings)
           end

    # Missed-cut players earn nothing.
    TournamentResult.where(tournament: tournament, made_cut: false)
                    .update_all(current_earnings_cents: 0)
  end

  ACCENT_MAP = {
    "À" => "A", "Á" => "A", "Â" => "A", "Ã" => "A", "Ä" => "A", "Å" => "A",
    "à" => "a", "á" => "a", "â" => "a", "ã" => "a", "ä" => "a", "å" => "a",
    "È" => "E", "É" => "E", "Ê" => "E", "Ë" => "E",
    "è" => "e", "é" => "e", "ê" => "e", "ë" => "e",
    "Ì" => "I", "Í" => "I", "Î" => "I", "Ï" => "I",
    "ì" => "i", "í" => "i", "î" => "i", "ï" => "i",
    "Ò" => "O", "Ó" => "O", "Ô" => "O", "Õ" => "O", "Ö" => "O", "Ø" => "O",
    "ò" => "o", "ó" => "o", "ô" => "o", "õ" => "o", "ö" => "o", "ø" => "o",
    "Ù" => "U", "Ú" => "U", "Û" => "U", "Ü" => "U",
    "ù" => "u", "ú" => "u", "û" => "u", "ü" => "u",
    "Ý" => "Y", "ý" => "y", "ÿ" => "y",
    "Ñ" => "N", "ñ" => "n",
    "Ç" => "C", "ç" => "c",
    "ß" => "ss"
  }.freeze

  def strip_accents(str)
    str.chars.map { |c| ACCENT_MAP[c] || c }.join
  end
end
