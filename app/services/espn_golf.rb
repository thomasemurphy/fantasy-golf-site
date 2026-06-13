class EspnGolf
  BASE_URL = "https://site.api.espn.com/apis/site/v2/sports/golf/pga"

  def initialize
    @conn = Faraday.new(url: BASE_URL) do |f|
      f.options.timeout = 10
      f.response :raise_error
    end
  end

  # Returns the active tournament leaderboard, or nil if none.
  # Result shape:
  #   { event_name:, completed:, period:, players: [
  #       { espn_id:, name:, rank:, position_display:,
  #         score_to_par:, thru:, current_round:, made_cut: }
  #   ]}
  def current_leaderboard(no_cut: false)
    data  = get("scoreboard")
    event = data["events"]&.first
    return nil unless event

    parse_event(event, no_cut: no_cut)
  rescue Faraday::Error => e
    Rails.logger.error "[EspnGolf] Request failed: #{e.message}"
    nil
  end

  private

  def get(path)
    JSON.parse(@conn.get(path).body)
  end

  def parse_event(event, no_cut: false)
    competition = event["competitions"]&.first
    return nil unless competition

    status    = competition.dig("status", "type") || {}
    completed = status["completed"] == true
    period    = competition.dig("status", "period").to_i  # current round (1-4)

    competitors = competition["competitors"] || []
    team_event  = competitors.any? { |c| c["type"] == "team" }

    # Classify each competitor as :active, :cut, or :wd up front (see
    # #competitor_status). We need this before ranking so missed-cut and
    # withdrawn players are excluded from the leaderboard positions.
    statuses = competitors.map { |c| competitor_status(c, period, no_cut: no_cut) }

    # Build score → { position, tied } map from players still in contention.
    # ESPN keeps missed-cut players in the R3+ feed (their linescores simply stop
    # at round 2), so we rank only the players who are still active.
    active_scores = competitors.each_index
                               .select { |i| statuses[i] == :active }
                               .map { |i| parse_score(competitors[i]["score"]) }
                               .sort

    score_meta = {}  # score_to_par => { pos:, tied: }
    pos = 1
    active_scores.chunk_while { |a, b| a == b }.each do |group|
      score_meta[group.first] = { pos: pos, tied: group.size > 1 }
      pos += group.size
    end

    players = competitors.each_index.map do |i|
      parse_competitor(competitors[i], period, completed, score_meta, statuses[i])
    end

    { event_name: event["name"], completed: completed, period: period,
      team_event: team_event, players: players }
  end

  # Classifies a competitor as :active (made the cut / still playing), :cut
  # (missed the cut), or :wd (withdrew). Team competitors are always :active.
  #
  # Cut detection: the 36-hole cut is applied after round 2. ESPN keeps
  # missed-cut players in the round-3+ feed, but their linescores stop at round
  # 2 — players who made the cut receive a round-3 entry (a tee-time stub at
  # minimum). So once the event reaches round 3, a player with no round-3-or-later
  # linescore has missed the cut.
  def competitor_status(c, period, no_cut: false)
    return :active if c["type"] == "team"

    rounds = c["linescores"] || []

    # ESPN signals WD in two ways:
    #   1. A round linescore has displayValue=="-" AND inner hole linescores exist
    #      (player started the round, played some holes, then withdrew).
    #      Note: pre-round stubs also use displayValue=="-" but have no inner linescores,
    #      so requiring linescores.present? excludes them.
    #   2. A round entry has actual strokes (value > 0) but no inner linescores
    #      (Morikawa-style: partial score recorded but hole data stripped).
    #      Pre-round stubs use value=0.0, so checking > 0 excludes them.
    withdrawn = rounds.any? { |r| r["displayValue"] == "-" && r["linescores"].to_a.any? } ||
                rounds.any? { |r| r["value"].to_f > 0 && r["linescores"].nil? }
    return :wd if withdrawn

    return :cut if !no_cut && period >= 3 && rounds.none? { |r| r["period"].to_i >= 3 }

    :active
  end

  def parse_competitor(c, period, completed, score_meta, status)
    return parse_team_competitor(c, period, completed, score_meta) if c["type"] == "team"

    score_to_par = parse_score(c["score"] || "E")
    rounds       = c["linescores"] || []
    tee_time     = extract_tee_time(rounds.find { |r| r["period"] == period })

    rank, position_display =
      case status
      when :wd  then [ nil, "WD" ]
      when :cut then [ nil, "CUT" ]
      else
        meta = score_meta[score_to_par] || { pos: 999, tied: false }
        pos  = meta[:pos]
        [ pos, meta[:tied] ? "T#{pos}" : pos.to_s ]
      end

    {
      espn_id:          c["id"],
      name:             c.dig("athlete", "fullName"),
      rank:             rank,
      position_display: position_display,
      score_to_par:     score_to_par,
      thru:             status == :active ? compute_thru(rounds, period, completed, false, tee_time) : nil,
      current_round:    period,
      made_cut:         status == :active
    }
  end

  def parse_team_competitor(c, period, completed, score_meta)
    score_str    = c["score"] || "E"
    score_to_par = parse_score(score_str)
    rounds       = c["linescores"] || []
    team_name    = c.dig("team", "displayName")

    meta = score_meta[score_to_par] || { pos: 999, tied: false }
    pos  = meta[:pos]

    {
      espn_team_name:   team_name,
      name:             team_name,
      rank:             pos,
      position_display: meta[:tied] ? "T#{pos}" : pos.to_s,
      score_to_par:     score_to_par,
      thru:             compute_thru(rounds, period, completed, false, nil),
      current_round:    period,
      made_cut:         true
    }
  end

  def parse_score(str)
    return 0 if str.nil? || str == "E"
    str.to_i
  end

  def compute_thru(rounds, period, completed, missed_cut, tee_time = nil)
    return nil if missed_cut
    return "F" if completed

    current_round_data = rounds.find { |r| r["period"] == period }
    return tee_time if current_round_data.nil?

    holes_played = current_round_data["linescores"]&.length.to_i
    if holes_played == 18
      "F"
    elsif holes_played > 0
      holes_played.to_s
    else
      tee_time  # on the tee sheet but hasn't started yet
    end
  end

  def extract_tee_time(round_linescore)
    return nil unless round_linescore
    stats = round_linescore.dig("statistics", "categories", 0, "stats") || []
    # The tee time entry has only a displayValue key (no numeric value)
    tee_stat = stats.find { |s| !s.key?("value") }
    return nil unless tee_stat
    # ESPN labels tee times with the local server timezone (e.g. "PDT") but the
    # actual value is Eastern time. Force parse as Eastern before converting.
    eastern_str = tee_stat["displayValue"].sub(/\b[A-Z]{2,4}\b/, "EDT")
    t = Time.parse(eastern_str).in_time_zone("Pacific Time (US & Canada)")
    tz = t.zone.sub(/[DS]T/, "T")  # PDT→PT, PST→PT, EDT→ET, etc.
    t.strftime("%-I:%M%p").downcase.sub("pm", "p").sub("am", "a") + " #{tz}"
  rescue
    nil
  end
end
