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
  def current_leaderboard
    data  = get("scoreboard")
    event = data["events"]&.first
    return nil unless event

    parse_event(event)
  rescue Faraday::Error => e
    Rails.logger.error "[EspnGolf] Request failed: #{e.message}"
    nil
  end

  private

  def get(path)
    JSON.parse(@conn.get(path).body)
  end

  def parse_event(event)
    competition = event["competitions"]&.first
    return nil unless competition

    status    = competition.dig("status", "type") || {}
    completed = status["completed"] == true
    period    = competition.dig("status", "period").to_i  # current round (1-4)

    competitors = competition["competitors"] || []

    # Build score → { position, tied } map for made-cut players.
    # ESPN gives sequential order values within ties; we re-derive ties from matching scores.
    made_cut_scores = competitors
      .reject { |c| period > 2 && c["linescores"].to_a.length < 3 }
      .map    { |c| parse_score(c["score"]) }
      .sort

    score_meta = {}  # score_to_par => { pos:, tied: }
    pos = 1
    made_cut_scores.chunk_while { |a, b| a == b }.each do |group|
      score_meta[group.first] = { pos: pos, tied: group.size > 1 }
      pos += group.size
    end

    players = competitors.map { |c| parse_competitor(c, period, completed, score_meta) }

    { event_name: event["name"], completed: completed, period: period, players: players }
  end

  def parse_competitor(c, period, completed, score_meta)
    score_str     = c["score"] || "E"
    score_to_par  = parse_score(score_str)
    rounds        = c["linescores"] || []
    rounds_played = rounds.length
    tee_time      = extract_tee_time(rounds.find { |r| r["period"] == period })

    # ESPN signals WD in two ways:
    #   1. A round linescore has displayValue=="-" AND inner hole linescores exist
    #      (player started the round, played some holes, then withdrew).
    #      Note: pre-round stubs also use displayValue=="-" but have no inner linescores,
    #      so requiring linescores.present? excludes them.
    #   2. A round entry has actual strokes (value > 0) but no inner linescores
    #      (Morikawa-style: partial score recorded but hole data stripped).
    #      Pre-round stubs use value=0.0, so checking > 0 excludes them.
    withdrawn  = rounds.any? { |r| r["displayValue"] == "-" && r["linescores"].to_a.any? } ||
                 rounds.any? { |r| r["value"].to_f > 0 && r["linescores"].nil? }
    missed_cut = !withdrawn && period > 2 && rounds_played < 3

    rank, position_display = if withdrawn
      [ nil, "WD" ]
    elsif missed_cut
      [ nil, "CUT" ]
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
      thru:             compute_thru(rounds, period, completed, missed_cut || withdrawn, tee_time),
      current_round:    period,
      made_cut:         !missed_cut && !withdrawn
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
    t = Time.parse(tee_stat["displayValue"])
            .in_time_zone("Pacific Time (US & Canada)")
    tz = t.zone.sub(/[DS]T/, "T")  # PDT→PT, PST→PT, EDT→ET, etc.
    t.strftime("%-I:%M%p").downcase.sub("pm", "p").sub("am", "a") + " #{tz}"
  rescue
    nil
  end
end
