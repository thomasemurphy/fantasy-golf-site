class SyncLiveLeaderboardJob < ApplicationJob
  queue_as :default

  def perform(tournament_id = nil)
    tournament = if tournament_id
      Tournament.find(tournament_id)
    else
      Tournament.find_by(status: "in_progress")
    end

    unless tournament
      Rails.logger.info "[SyncLiveLeaderboardJob] No in_progress tournament found"
      return
    end

    data = EspnGolf.new.current_leaderboard

    unless data
      Rails.logger.warn "[SyncLiveLeaderboardJob] No active ESPN event returned"
      return
    end

    players = data[:players]
    period  = data[:period]
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
    end

    if data[:completed] && tournament.status == "in_progress"
      tournament.update!(status: "completed")
      Rails.logger.info "[SyncLiveLeaderboardJob] Marked #{tournament.name} as completed"
    end

    Rails.logger.info "[SyncLiveLeaderboardJob] ESPN sync complete: #{tournament.name} " \
                      "R#{period} — #{players.size} players"
  end

  private

  # Finds an existing Golfer by name (with normalization fallbacks),
  # or creates a new one using the ESPN display name.
  def find_or_create_golfer(espn_name)
    find_golfer(espn_name) || Golfer.create!(name: espn_name)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "[SyncLiveLeaderboardJob] Could not create golfer '#{espn_name}': #{e.message}"
    nil
  end

  def find_golfer(espn_name)
    # 1. Exact match
    return Golfer.find_by(name: espn_name) if Golfer.exists?(name: espn_name)

    # 2. Normalize: remove dots (J.J. → JJ)
    normalized = espn_name.gsub(".", "").squeeze(" ").strip
    return Golfer.find_by(name: normalized) if Golfer.exists?(name: normalized)

    # 3. Last-name-only fallback — only when it uniquely identifies one golfer
    last_name = espn_name.split.last
    matches   = Golfer.where("name ILIKE ?", "%#{last_name}")
    matches.first if matches.one?
  end
end
