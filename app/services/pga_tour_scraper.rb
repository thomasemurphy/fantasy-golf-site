class PgaTourScraper
  GRAPHQL_URL = "https://orchestrator.pgatour.com/graphql"
  API_KEY     = "da2-gsrx5bibzbb4njvhl7t37nzdn4"

  def initialize
    @conn = Faraday.new(url: GRAPHQL_URL) do |f|
      f.options.timeout = 15
      f.response :raise_error
    end
  end

  # Returns an array of { name:, position_display:, position:, score_to_par:, made_cut:, earnings_cents: }
  # for all players in the given PGA Tour tournament (e.g. pgatour_id = "R2026011").
  def results(pgatour_id)
    year = pgatour_id.match(/(\d{4})/)[1].to_i

    query = <<~GQL
      {
        tournamentPastResults(id: "#{pgatour_id}", year: #{year}) {
          players {
            position
            parRelativeScore
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
      pos_str      = p["position"].to_s
      missed_cut   = %w[CUT W/D DQ].include?(pos_str)
      earnings_str = p.dig("additionalData", 1) || "$0.00"

      {
        name:             p.dig("player", "displayName"),
        position_display: pos_str,
        position:         missed_cut ? nil : pos_str.delete("T").to_i,
        score_to_par:     missed_cut ? nil : p["parRelativeScore"].to_i,
        made_cut:         !missed_cut,
        earnings_cents:   parse_earnings(earnings_str)
      }
    end
  rescue Faraday::Error => e
    Rails.logger.error "[PgaTourScraper] Request failed: #{e.message}"
    []
  end

  # Convenience alias kept for backwards compatibility
  alias payouts results

  # Authoritative cut status for a live (or completed) tournament.
  # Returns a Hash mapping GolferName.key(name) => :cut or :wd for every player
  # who missed the cut or withdrew/was DQ'd. Players still in contention are
  # omitted. The PGA Tour applies the cut to the 36-hole score for us (handling
  # ties and each major's cut rule), so a player's `position` of "CUT" is the
  # source of truth.
  #
  # Returns nil if the request fails or no leaderboard is available — callers
  # treat nil as "no authoritative data, fall back to the heuristic". An empty
  # hash (query succeeded, nobody cut yet) is a distinct, valid result.
  def live_cut_status(pgatour_id)
    query = <<~GQL
      {
        leaderboardV2(id: "#{pgatour_id}") {
          players {
            __typename
            ... on PlayerRowV2 {
              position
              player { displayName }
            }
          }
        }
      }
    GQL

    response = @conn.post do |req|
      req.headers["Content-Type"] = "application/json"
      req.headers["x-api-key"]    = API_KEY
      req.body = { query: query }.to_json
    end

    players = JSON.parse(response.body).dig("data", "leaderboardV2", "players")
    return nil if players.nil?

    status = {}
    players.each do |row|
      next unless row["__typename"] == "PlayerRowV2"
      name = row.dig("player", "displayName")
      next if name.blank?

      case row["position"].to_s.upcase
      when "CUT"
        status[GolferName.key(name)] = :cut
      when "WD", "W/D", "DQ"
        status[GolferName.key(name)] = :wd
      end
    end
    status
  rescue Faraday::Error => e
    Rails.logger.error "[PgaTourScraper] live_cut_status request failed: #{e.message}"
    nil
  end

  private

  def parse_earnings(str)
    (str.to_s.gsub(/[$,]/, "").to_f * 100).round
  end
end
