class PgaTourScraper
  GRAPHQL_URL = "https://orchestrator.pgatour.com/graphql"
  API_KEY     = "da2-gsrx5bibzbb4njvhl7t37nzdn4"

  def initialize
    @conn = Faraday.new(url: GRAPHQL_URL) do |f|
      f.options.timeout = 15
      f.response :raise_error
    end
  end

  # Returns an array of { name:, position:, earnings_cents: } for all players
  # in the given PGA Tour tournament (e.g. pgatour_id = "R2026011").
  def payouts(pgatour_id)
    year = pgatour_id.match(/(\d{4})/)[1].to_i

    query = <<~GQL
      {
        tournamentPastResults(id: "#{pgatour_id}", year: #{year}) {
          players {
            position
            player { displayName }
            additionalData
          }
        }
      }
    GQL

    response = @conn.post do |req|
      req.headers["Content-Type"] = "application/json"
      req.headers["x-api-key"]    = API_KEY
      req.body = { query: query }.to_json
    end

    players = JSON.parse(response.body).dig("data", "tournamentPastResults", "players") || []

    players.map do |p|
      earnings_str = p.dig("additionalData", 1) || "$0.00"
      {
        name:           p.dig("player", "displayName"),
        position:       p["position"],
        earnings_cents: parse_earnings(earnings_str)
      }
    end
  rescue Faraday::Error => e
    Rails.logger.error "[PgaTourScraper] Request failed: #{e.message}"
    []
  end

  private

  def parse_earnings(str)
    (str.to_s.gsub(/[$,]/, "").to_f * 100).round
  end
end
