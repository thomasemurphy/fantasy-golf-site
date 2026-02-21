class SyncTournamentResultsJob < ApplicationJob
  queue_as :default

  def perform(tournament_id = nil)
    tournament = if tournament_id
      Tournament.find(tournament_id)
    else
      # Find the most recently completed / in-progress tournament
      Tournament.where(status: %w[in_progress completed])
                .order(:end_date)
                .last
    end

    unless tournament
      Rails.logger.info "[SyncTournamentResultsJob] No tournament to sync results for"
      return
    end

    unless tournament.sportsdata_id.present?
      Rails.logger.warn "[SyncTournamentResultsJob] Tournament #{tournament.id} has no sportsdata_id"
      return
    end

    api = SportsDataIo.new
    data = api.leaderboard(tournament.sportsdata_id)

    players = data["Players"] || []
    is_over = data["IsOver"] || false

    ApplicationRecord.transaction do
      players.each do |player_data|
        sportsdata_player_id = player_data["PlayerID"]&.to_s
        golfer = Golfer.find_by(sportsdata_id: sportsdata_player_id)
        next unless golfer

        made_cut = player_data["MadeCut"]
        position = player_data["Rank"]&.to_i
        earnings = ((player_data["TotalEarnings"] || 0) * 100).to_i

        result = TournamentResult.find_or_initialize_by(
          tournament: tournament,
          golfer: golfer
        )
        result.update!(
          position: position,
          earnings_cents: earnings,
          made_cut: made_cut
        )
      end

      # Update all picks for this tournament
      tournament.picks.each do |pick|
        result = TournamentResult.find_by(tournament: tournament, golfer: pick.golfer)
        next unless result

        pick.made_cut = result.made_cut
        if pick.auto_assigned?
          pick.earnings_cents = 0
        else
          base = result.earnings_cents || 0
          pick.earnings_cents = pick.is_double_down? ? base * 2 : base
        end
        pick.save!
      end

      # Mark tournament as completed if the API says it's over
      tournament.update!(status: "completed") if is_over
    end

    Rails.logger.info "[SyncTournamentResultsJob] Synced results for #{tournament.name} (#{players.size} players)"
  end
end
