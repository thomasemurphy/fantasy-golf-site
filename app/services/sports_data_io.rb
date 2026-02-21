class SportsDataIo
  BASE_URL = "https://api.sportsdata.io/golf/v2/json"

  def initialize
    @api_key = ENV.fetch("SPORTSDATA_API_KEY") { Rails.application.credentials.sportsdata_api_key }
    @conn = Faraday.new(url: BASE_URL) do |f|
      f.response :raise_error
    end
  end

  # GET /golf/v2/json/Tournaments/{season}
  # Returns array of tournament hashes for a given season year
  def tournaments(season = Date.current.year)
    get("Tournaments/#{season}")
  end

  # GET /golf/v2/json/Leaderboard/{tournamentId}
  # Returns leaderboard with player results + earnings
  def leaderboard(sportsdata_tournament_id)
    get("Leaderboard/#{sportsdata_tournament_id}")
  end

  # GET /golf/v2/json/PlayerTournamentStatsByPlayer/{tournamentId}/{playerId}
  # Returns field (players entered) for a tournament
  def tournament_players(sportsdata_tournament_id)
    get("PlayerTournamentProjections/#{sportsdata_tournament_id}")
  rescue Faraday::ResourceNotFound
    # Some tournaments don't have projections yet; fall back to leaderboard
    data = leaderboard(sportsdata_tournament_id)
    data["Players"] || []
  end

  private

  def get(path)
    response = @conn.get(path, { key: @api_key })
    JSON.parse(response.body)
  end
end
