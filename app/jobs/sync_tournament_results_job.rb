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

      # Sync made_cut onto picks so no-cut challenge tracking is accurate.
      # Earnings are entered separately via the admin earnings form.
      tournament.picks.each do |pick|
        result = TournamentResult.find_by(tournament: tournament, golfer: pick.golfer)
        next unless result
        pick.update_column(:made_cut, result.made_cut)
      end

      if data[:completed] && tournament.status == "in_progress"
        tournament.update!(status: "completed")
        Rails.logger.info "[SyncTournamentResultsJob] Marked #{tournament.name} as completed"
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

    last_name = espn_name.split.last
    matches   = Golfer.where("name ILIKE ?", "%#{last_name}")
    matches.first if matches.one?
  end
end
