class SyncTournamentFieldJob < ApplicationJob
  queue_as :default

  def perform(tournament_id = nil)
    tournament = if tournament_id
      Tournament.find(tournament_id)
    else
      # Find the next upcoming tournament that hasn't had its field synced
      Tournament.upcoming.where(status: "upcoming").order(:start_date).first
    end

    unless tournament
      Rails.logger.info "[SyncTournamentFieldJob] No upcoming tournament found"
      return
    end

    unless tournament.sportsdata_id.present?
      Rails.logger.warn "[SyncTournamentFieldJob] Tournament #{tournament.id} has no sportsdata_id"
      return
    end

    api = SportsDataIo.new
    players = api.tournament_players(tournament.sportsdata_id)

    player_list = extract_players(players)

    player_list.each do |player_data|
      sportsdata_player_id = player_data["PlayerID"]&.to_s
      name = [ player_data["FirstName"], player_data["LastName"] ].compact.join(" ").strip

      next if name.blank?

      golfer = Golfer.find_or_create_by(sportsdata_id: sportsdata_player_id) do |g|
        g.name = name
      end
      golfer.update(name: name) if golfer.name != name

      TournamentEntry.find_or_create_by(tournament: tournament, golfer: golfer)
    end

    Rails.logger.info "[SyncTournamentFieldJob] Synced #{player_list.size} players for #{tournament.name}"
  end

  private

  def extract_players(data)
    # API can return array directly or hash with Players key
    if data.is_a?(Array)
      data
    elsif data.is_a?(Hash)
      data["Players"] || data["PlayerTournamentProjections"] || []
    else
      []
    end
  end
end
