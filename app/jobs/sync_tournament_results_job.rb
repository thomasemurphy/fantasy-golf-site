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

    # Stop working once the event is final and its authoritative earnings are in.
    # The recurring task keeps firing on its schedule, but there's nothing left to
    # do until the next tournament becomes active — so exit immediately instead of
    # re-hitting ESPN/PGA and re-projecting an already-finished leaderboard.
    if tournament.status == "completed" && earnings_finalized?(tournament)
      Rails.logger.info "[SyncTournamentResultsJob] #{tournament.name} already completed " \
                        "with earnings synced — nothing to do"
      return
    end

    cut_status = fetch_cut_status(tournament)
    data = EspnGolf.new.current_leaderboard(no_cut: tournament.no_cut?, cut_status: cut_status)

    unless data
      Rails.logger.warn "[SyncTournamentResultsJob] No active ESPN event returned"
      return
    end

    # Sanity-check: verify ESPN is returning data for this tournament.
    # Match on shared distinctive words rather than the last word, since ESPN's
    # event name can differ from ours (e.g. ESPN "U.S. Open" vs "U.S. Open
    # Championship", "the Memorial Tournament" vs "Memorial Tournament").
    unless event_matches?(data[:event_name], tournament.name)
      Rails.logger.warn "[SyncTournamentResultsJob] ESPN event '#{data[:event_name]}' " \
                        "does not match tournament '#{tournament.name}' — skipping"
      return
    end

    players = data[:players]

    ApplicationRecord.transaction do
      synced_golfer_ids = []
      players.each do |p|
        golfers_to_update = if p[:espn_team_name]
          find_golfers_for_team(tournament, p[:espn_team_name])
        else
          [find_or_create_golfer(p[:name])].compact
        end

        golfers_to_update.each do |golfer|
          synced_golfer_ids << golfer.id
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
      end

      prune_stale_results(tournament, synced_golfer_ids)

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
        Rails.logger.info "[SyncTournamentResultsJob] Marked #{tournament.name} as completed"
      end
    end

    # Pull authoritative final earnings whenever the event is completed but its
    # earnings haven't been finalized yet. This covers the tournament we just
    # marked completed above, and also retries on a later tick if a previous
    # earnings sync failed — so the recurring job keeps trying until earnings
    # land, after which the guard at the top of #perform makes it stop.
    if tournament.status == "completed" && !earnings_finalized?(tournament)
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

  # True once authoritative final earnings have been written for the tournament.
  # SyncTournamentResultsJob only ever writes current_earnings_cents (the live
  # projection); earnings_cents is set exclusively by SyncTournamentEarningsJob
  # (and historical manual seeds), so any non-nil earnings_cents means the final
  # earnings sync has already run.
  def earnings_finalized?(tournament)
    TournamentResult.where(tournament: tournament).where.not(earnings_cents: nil).exists?
  end

  # Authoritative cut/WD status from PGA Tour, or nil when not applicable
  # (no-cut event, or no pgatour_id) or when the fetch fails. EspnGolf treats nil
  # as "fall back to the linescore heuristic".
  def fetch_cut_status(tournament)
    return nil if tournament.no_cut? || tournament.pgatour_id.blank?
    PgaTourScraper.new.live_cut_status(tournament.pgatour_id)
  end

  # Generic words shared by many event names; ignored when matching so that two
  # unrelated events don't match just because both end in "Championship".
  GENERIC_EVENT_WORDS = %w[
    the of at and a championship championships tournament invitational
    classic open presented by golf pga tour
  ].to_set.freeze

  # True if the ESPN event name and our tournament name share at least one
  # distinctive (non-generic) word. ESPN only ever returns the single active
  # PGA event, so this is a guard against syncing during an off week.
  def event_matches?(espn_name, tournament_name)
    significant = ->(name) {
      name.to_s.downcase.gsub(/[^a-z0-9 ]/, " ").split.reject { |w| GENERIC_EVENT_WORDS.include?(w) }.to_set
    }
    espn = significant.call(espn_name)
    ours = significant.call(tournament_name)
    return false if espn.empty? || ours.empty?
    espn.intersect?(ours)
  end

  def find_golfers_for_team(tournament, espn_team_name)
    pairing = TeamPairing.find_by(tournament: tournament, espn_team_name: espn_team_name)
    if pairing
      pairing.golfers
    else
      # Fall back to last-name matching for teams not in the pairings table
      espn_team_name.split("/").filter_map do |last_name|
        Golfer.all.find { |g| g.name.split.last.casecmp?(last_name) }
      end
    end
  end

  # Remove TournamentResult rows for golfers that ESPN no longer returns in the
  # live field. ESPN occasionally emits a transient/misnamed competitor (e.g. a
  # placeholder name during Round 1) that later disappears from the feed; because
  # we only upsert golfers present in the current response, such a row would
  # otherwise linger forever, frozen at its last-synced state, and show up as a
  # phantom player on the leaderboard.
  #
  # Only prunes while the tournament is still in_progress (a completed event's
  # results are authoritative and edited separately), and never deletes a result
  # tied to a pool pick — real players don't vanish from the feed mid-event, so a
  # picked golfer going missing signals a transient ESPN hiccup we should ride out
  # rather than destroy data behind a user's pick.
  def prune_stale_results(tournament, synced_golfer_ids)
    return unless tournament.status == "in_progress"

    picked_golfer_ids = tournament.picks.pluck(:golfer_id)
    stale = TournamentResult.where(tournament: tournament)
                            .where.not(golfer_id: synced_golfer_ids + picked_golfer_ids)
    return if stale.empty?

    names = stale.includes(:golfer).map { |r| r.golfer.name }
    count = stale.delete_all
    Rails.logger.info "[SyncTournamentResultsJob] Pruned #{count} stale result(s) " \
                      "not in ESPN field: #{names.join(', ')}"
  end

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
    stripped = GolferName.strip_accents(espn_name)
    Golfer.all.each do |g|
      return g if GolferName.strip_accents(g.name) == stripped
    end

    nil
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

    # Group made-cut entries by numeric position to handle ties correctly.
    # For team events, both partners share the same position row — count them as
    # one scoring unit (not two separate competitors splitting the purse).
    results.select { |r| r.made_cut? && r.current_position }
           .group_by(&:current_position)
           .each do |position, tied_results|
             units = if tournament.is_team_event?
               # Each pair of golfers at the same position counts as one team unit
               tied_results.size / 2
             else
               tied_results.size
             end
             units = [units, 1].max
             total_pct = (position...position + units).sum { |p| PAYOUT_PERCENTAGES[p] || 0.0 }
             earnings = (purse * total_pct / 100.0 / units).round
             TournamentResult.where(id: tied_results.map(&:id))
                             .update_all(current_earnings_cents: earnings)
           end

    # Missed-cut players earn nothing.
    TournamentResult.where(tournament: tournament, made_cut: false)
                    .update_all(current_earnings_cents: 0)
  end
end
