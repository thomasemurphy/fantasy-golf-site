class StandingsController < ApplicationController
  skip_before_action :authenticate_user!

  REFRESH_COOLDOWN = 60 # seconds

  def refresh
    tournament = Tournament.find_by(status: "in_progress")
    unless tournament
      redirect_to standings_path and return
    end

    last = Rails.cache.read("standings_last_refreshed")
    if last && Time.current - last < REFRESH_COOLDOWN
      remaining = (REFRESH_COOLDOWN - (Time.current - last)).ceil
      redirect_to standings_path(tab: params[:return_tab].presence || "live", live_sub: params[:live_sub].presence),
                  flash: { notice: "Leaderboard was just updated. Try again in #{remaining}s." }
      return
    end

    SyncTournamentResultsJob.perform_now(tournament.id)
    Rails.cache.write("standings_last_refreshed", Time.current, expires_in: 10.minutes)
    redirect_to standings_path(tab: params[:return_tab].presence || "live", live_sub: params[:live_sub].presence)
  end

  def index
    @live_tournament       = Tournament.find_by(status: "in_progress")
    @completed_tournaments = Tournament.where(status: %w[completed in_progress])
                                       .joins(:picks).distinct.order(:week_number)
    @no_cut_users  = no_cut_survivors
    @last_refreshed = Rails.cache.read("standings_last_refreshed")
    @sort = params[:sort].presence
    @dir  = %w[asc desc].include?(params[:dir]) ? params[:dir] : nil

    # Determine which tab to open on page load
    @initial_live_sub = params[:live_sub].presence || "pool"

    @initial_tab = if params[:tournament_id].present?
      "t#{params[:tournament_id]}"
    elsif params[:tab].present?
      params[:tab]
    elsif @live_tournament
      "live"
    else
      "overall"
    end
    @initial_tab = "overall" if @initial_tab == "live" && @live_tournament.nil?

    # All-golfers season leaderboard for the overall tab
    completed_tids = Tournament.where(status: "completed").pluck(:id)
    completed_tournaments_ordered = Tournament.where(id: completed_tids).order(:week_number).to_a
    golfer_results = TournamentResult.where(tournament_id: completed_tids).includes(:golfer).to_a
    results_by_gt = golfer_results.index_by { |r| [r.golfer_id, r.tournament_id] }
    sorted = golfer_results
      .group_by(&:golfer_id)
      .map do |gid, rs|
        history = completed_tournaments_ordered.map do |t|
          { tournament: t, result: results_by_gt[[gid, t.id]] }
        end
        { golfer: rs.first.golfer, earnings_cents: rs.sum { |r| r.earnings_cents.to_i }, history: history }
      end
      .sort_by { |g| [-g[:earnings_cents], g[:golfer].name] }
    rank = 1
    @all_season_golfers = sorted.chunk_while { |a, b| a[:earnings_cents] == b[:earnings_cents] }.flat_map do |group|
      display = group.size > 1 ? "T#{rank}" : rank.to_s
      rank += group.size
      group.map { |g| g.merge(rank: display) }
    end

    # Load all standings data at once so tab switching is instant
    @pot_tournaments = {
      "majors"      => Tournament.where(tournament_type: "major").order(:week_number).to_a,
      "side_events" => Tournament.where(tournament_type: "side_event").order(:week_number).to_a,
      "pink_events" => Tournament.where(tournament_type: "pink_event").order(:week_number).to_a,
    }

    @overall_standings      = compute_standings("overall")
    @majors_standings       = compute_standings("majors")
    @side_events_standings  = compute_standings("side_events")
    @pink_events_standings  = compute_standings("pink_events")
    @first_half_standings   = compute_standings("first_half")
    @second_half_standings  = compute_standings("second_half")

    if @live_tournament
      @live_pool_standings  = live_standings(@live_tournament)
      @live_field_standings = field_standings(@live_tournament)
    end

    @tournament_data = @completed_tournaments
      .reject { |t| t.status == "in_progress" }
      .map    { |t| { tournament: t, pool: tournament_standings(t), field: field_standings(t) } }
  end

  private

  def compute_standings(tab)
    sort = (@initial_tab == tab ? @sort : nil) || "earnings"
    dir  = (@initial_tab == tab ? @dir  : nil) || "desc"

    users = User.where(approved: true).where.not(name: "Commissioner")
                .includes(picks: [:golfer, :tournament])

    completed_tid = Tournament.where(status: "completed").pluck(:id)
    results_index = TournamentResult.where(tournament_id: completed_tid)
                                    .index_by { |r| [r.tournament_id, r.golfer_id] }

    # Live pick data for in-progress tournament tooltip
    live_pick_by_user_id = {}
    if @live_tournament
      live_picks = Pick.where(tournament: @live_tournament, user_id: users.map(&:id))
                       .includes(:golfer).index_by(&:user_id)
      live_results = TournamentResult.where(tournament: @live_tournament).index_by(&:golfer_id)
      live_pick_by_user_id = live_picks.transform_values do |pick|
        result = live_results[pick.golfer_id]
        { pick: pick, position: result&.current_position_display }
      end
    end

    # Rank is always earnings-based, independent of display sort
    by_earnings = users.sort_by { |u| [-earnings_for_tab(u, tab), u.name] }
    rank = 1
    rows = by_earnings.chunk_while { |a, b| earnings_for_tab(a, tab) == earnings_for_tab(b, tab) }.flat_map do |group|
      display = group.size > 1 ? "T#{rank}" : rank.to_s
      rank += group.size
      group.map do |user|
        completed_picks = user.picks
                              .select { |p| p.tournament.status == "completed" }
                              .sort_by { |p| p.tournament.week_number }
                              .map { |p|
                                result = results_index[[p.tournament_id, p.golfer_id]]
                                { pick: p, position: result&.current_position_display }
                              }
        total_earnings = user.picks.sum { |p| p.earnings_cents.to_i }
        { rank: display, user: user, earnings_cents: earnings_for_tab(user, tab), completed_picks: completed_picks, total_earnings_cents: total_earnings, live_pick: live_pick_by_user_id[user.id] }
      end
    end

    # Apply display sort
    rows.sort_by! do |row|
      u = row[:user]
      case sort
      when "player"   then u.name
      when "dd"       then u.double_downs_remaining
      when "nocut"    then u.no_cut_streak_alive? ? 0 : 1
      else                 [-row[:earnings_cents].to_i, u.name]
      end
    end
    rows.reverse! if %w[earnings dd nocut].include?(sort) && dir == "asc"
    rows.reverse! if sort == "player" && dir == "desc"
    rows
  end

  def tournament_standings(tournament)
    sort = (@initial_tab == "t#{tournament.id}" ? @sort : nil) || "earnings"
    dir  = (@initial_tab == "t#{tournament.id}" ? @dir  : nil) || "desc"

    picks = Pick.where(tournament: tournament)
                .joins("LEFT JOIN tournament_results ON tournament_results.tournament_id = picks.tournament_id
                        AND tournament_results.golfer_id = picks.golfer_id")
                .select("picks.*, tournament_results.current_position, " \
                        "tournament_results.current_position_display, tournament_results.current_score_to_par")
                .preload(:user, :golfer)
                .to_a

    # Preload pick history for tooltip
    user_ids = picks.map { |p| p.user_id }.uniq
    completed_tid = Tournament.where(status: "completed").pluck(:id)
    completed_tournaments_ordered = Tournament.where(id: completed_tid).order(:week_number).to_a
    results_index = TournamentResult.where(tournament_id: completed_tid)
                                    .index_by { |r| [r.tournament_id, r.golfer_id] }
    history_picks = Pick.where(user_id: user_ids, tournament_id: completed_tid)
                        .includes(:golfer, :tournament)
                        .to_a
                        .group_by(&:user_id)
    history_by_user = history_picks.transform_values do |user_picks|
      user_picks.sort_by { |p| p.tournament.week_number }
                .map { |p|
                  result = results_index[[p.tournament_id, p.golfer_id]]
                  { pick: p, position: result&.current_position_display }
                }
    end
    total_earnings_by_user = history_picks.transform_values { |ups| ups.sum { |p| p.earnings_cents.to_i } }

    # Preload golfer history for golfer tooltip
    golfer_ids = picks.map(&:golfer_id).uniq
    golfer_history = golfer_ids.index_with do |gid|
      completed_tournaments_ordered.map do |t|
        { tournament: t, result: results_index[[t.id, gid]] }
      end
    end

    # --- Compute overall rank for tooltip header ---
    all_users = User.where(approved: true).where.not(name: "Commissioner").to_a
    overall_rank_by_user_id = {}
    overall_rank = 1
    all_users.sort_by { |u| [-u.total_earnings_cents.to_i, u.name] }
             .chunk_while { |a, b| a.total_earnings_cents.to_i == b.total_earnings_cents.to_i }
             .each do |group|
               display = group.size > 1 ? "T#{overall_rank}" : overall_rank.to_s
               group.each { |u| overall_rank_by_user_id[u.id] = display }
               overall_rank += group.size
             end

    # --- Compute earnings-based display rank, independent of current sort ---
    # bottom_val: 0=active, 1=CUT, 2=WD — rank is "—" for anything > 0
    bottom_val = ->(p) {
      case p.current_position_display
      when "WD"  then 2
      when "CUT" then 1
      else 0
      end
    }
    by_earnings = picks.sort_by { |p| [bottom_val.call(p), -(p.earnings_cents || 0), p.current_position || 9999, p.golfer.name, p.user.name] }

    rank_by_id = {}
    rank = 1
    by_earnings.chunk_while { |a, b|
      bottom_val.call(a) == 0 && bottom_val.call(b) == 0 && (a.earnings_cents || 0) == (b.earnings_cents || 0)
    }.each do |group|
      if bottom_val.call(group.first) > 0
        group.each { |p| rank_by_id[p.id] = "—" }
      else
        display = group.size > 1 ? "T#{rank}" : rank.to_s
        group.each { |p| rank_by_id[p.id] = display }
        rank += group.size
      end
    end

    # --- Sort rows by user-selected column ---
    # dd_val: 0=double-down, 1=regular — clusters doubles ahead of non-doubles for earnings sort
    dd_val = ->(p) { p.is_double_down? ? 0 : 1 }

    picks.sort_by! do |p|
      bot = bottom_val.call(p)
      case sort
      when "player"   then [p.user.name]
      when "golfer"   then [p.golfer.name]
      when "pos"      then [bot, p.current_position || 9999, p.golfer_id, p.user.name]
      when "earnings"
        base = p.earnings_cents || 0
        earnings_val = dir == "desc" ? -base : base
        if bot == 0
          [0, earnings_val, p.current_position || 9999, p.golfer.name, p.user.name]
        elsif bot == 1
          [1, p.current_score_to_par || 999, p.golfer.name, p.user.name]
        else
          [2, dd_val.call(p), p.golfer.name, p.user.name]
        end
      else # score
        [bot, p.current_position || 9999, p.golfer.name, p.user.name]
      end
    end

    picks.reverse! if %w[player golfer].include?(sort) && dir == "desc"
    if dir == "desc" && sort == "score"
      picks.reverse!
      picks.sort_by!.with_index { |p, i| [bottom_val.call(p), i] }
    end

    picks.map do |pick|
      {
        rank:                  rank_by_id[pick.id] || "—",
        overall_rank:          overall_rank_by_user_id[pick.user_id] || "—",
        user:                  pick.user,
        golfer:                pick.golfer,
        pick:                  pick,
        position_display:      pick.current_position_display,
        score_to_par:          pick.current_score_to_par,
        earnings_cents:        pick.earnings_cents,
        completed_picks:       history_by_user[pick.user_id] || [],
        total_earnings_cents:  total_earnings_by_user[pick.user_id] || 0,
        golfer_history:        golfer_history[pick.golfer_id] || []
      }
    end
  end

  def earnings_for_tab(user, tab)
    case tab
    when "majors"       then user.majors_earnings_cents
    when "side_events"  then user.side_events_earnings_cents
    when "pink_events"  then user.pink_events_earnings_cents
    when "first_half"   then user.first_half_earnings_cents
    when "second_half"  then user.second_half_earnings_cents
    else user.total_earnings_cents
    end
  end

  def live_standings(tournament)
    sort = (@initial_tab == "live" ? @sort : nil) || "earnings"
    dir  = (@initial_tab == "live" ? @dir  : nil) || "desc"

    picks = Pick.where(tournament: tournament)
                .joins("LEFT JOIN tournament_results ON tournament_results.tournament_id = picks.tournament_id AND tournament_results.golfer_id = picks.golfer_id")
                .select("picks.*, " \
                        "tournament_results.current_position, tournament_results.current_position_display, " \
                        "tournament_results.current_score_to_par, tournament_results.current_thru, " \
                        "tournament_results.current_round, tournament_results.current_earnings_cents")
                .preload(:user, :golfer)
                .to_a

    # Preload completed pick history for tooltips
    user_ids = picks.map(&:user_id).uniq
    completed_tid = Tournament.where(status: "completed").pluck(:id)
    completed_tournaments_ordered = Tournament.where(id: completed_tid).order(:week_number).to_a
    results_index = TournamentResult.where(tournament_id: completed_tid)
                                    .index_by { |r| [r.tournament_id, r.golfer_id] }
    history_picks = Pick.where(user_id: user_ids, tournament_id: completed_tid)
                        .includes(:golfer, :tournament).to_a.group_by(&:user_id)
    history_by_user = history_picks.transform_values do |ups|
      ups.sort_by { |p| p.tournament.week_number }
         .map { |p| { pick: p, position: results_index[[p.tournament_id, p.golfer_id]]&.current_position_display } }
    end
    total_earnings_by_user = history_picks.transform_values { |ups| ups.sum { |p| p.earnings_cents.to_i } }

    # Golfer history for golfer tooltips
    golfer_ids = picks.map(&:golfer_id).uniq
    golfer_history = golfer_ids.index_with do |gid|
      completed_tournaments_ordered.map do |t|
        { tournament: t, result: results_index[[t.id, gid]] }
      end
    end

    # Overall rank for tooltip header
    all_users = User.where(approved: true).where.not(name: "Commissioner").to_a
    overall_rank_by_user_id = {}
    overall_rank = 1
    all_users.sort_by { |u| [-u.total_earnings_cents.to_i, u.name] }
             .chunk_while { |a, b| a.total_earnings_cents.to_i == b.total_earnings_cents.to_i }
             .each do |group|
               display = group.size > 1 ? "T#{overall_rank}" : overall_rank.to_s
               group.each { |u| overall_rank_by_user_id[u.id] = display }
               overall_rank += group.size
             end

    # 0=started, 1=not_started, 2=CUT, 3=WD, 4=auto
    started_thru = ->(p) { p.current_thru&.match?(/\A\d+\z/) || p.current_thru == "F" }
    tier = ->(p) {
      if p.auto_assigned?                          then 4
      elsif p.current_position_display == "WD"     then 3
      elsif p.current_position_display == "CUT"    then 2
      elsif started_thru.call(p)                   then 0
      else                                              1
      end
    }
    effective_proj = ->(p) { p.auto_assigned? ? 0 : (p.is_double_down? ? p.current_earnings_cents.to_i * 2 : p.current_earnings_cents.to_i) }
    dd_val         = ->(p) { p.is_double_down? ? 0 : 1 }

    picks.sort_by! do |p|
      t = tier.call(p)
      case sort
      when "player"   then [t, p.user.name]
      when "golfer"   then [t, p.golfer.name, p.user.name]
      when "pos"      then [t, p.current_position || 9999, p.golfer.name, p.user.name]
      when "thru"     then [t, thru_sort_val(p.current_thru), p.golfer.name, p.user.name]
      when "earnings"
        if t == 0
          [0, -effective_proj.call(p), p.golfer.name, p.user.name]
        else
          [t, p.golfer.name, p.user.name]
        end
      else # "score"
        [t, p.current_score_to_par || 999, thru_sort_val(p.current_thru), p.golfer.name, p.user.name]
      end
    end
    picks.reverse! if %w[player golfer].include?(sort) && dir == "desc"

    # Tie-aware rank: only started (tier 0) players receive a numeric rank
    by_earnings = picks.sort_by { |p| [tier.call(p), -effective_proj.call(p), p.golfer.name, p.user.name] }
    rank_by_id = {}
    rank = 1
    by_earnings.chunk_while { |a, b|
      tier.call(a) == 0 && tier.call(b) == 0 && effective_proj.call(a) == effective_proj.call(b)
    }.each do |group|
      if tier.call(group.first) > 0
        group.each { |p| rank_by_id[p.id] = "—" }
      else
        display = group.size > 1 ? "T#{rank}" : rank.to_s
        group.each { |p| rank_by_id[p.id] = display }
        rank += group.size
      end
    end

    picks.map do |pick|
      {
        rank:                   rank_by_id[pick.id] || "—",
        user:                   pick.user,
        golfer:                 pick.golfer,
        pick:                   pick,
        position_display:       pick.current_position_display,
        score_to_par:           pick.current_score_to_par,
        thru:                   pick.current_thru,
        round:                  pick.current_round,
        current_earnings_cents: pick.auto_assigned? ? 0 : (pick.is_double_down? ? pick.current_earnings_cents.to_i * 2 : pick.current_earnings_cents),
        completed_picks:        history_by_user[pick.user_id] || [],
        total_earnings_cents:   total_earnings_by_user[pick.user_id] || 0,
        overall_rank:           overall_rank_by_user_id[pick.user_id] || "—",
        golfer_history:         golfer_history[pick.golfer_id] || []
      }
    end
  end

  def field_standings(tournament)
    # All synced results for this tournament (one per golfer in the field)
    results = TournamentResult.where(tournament: tournament).includes(:golfer).to_a

    # Pool picks for this tournament, keyed by golfer_id
    picks_by_golfer = Pick.where(tournament: tournament)
                          .includes(:user)
                          .group_by(&:golfer_id)

    rows = results.map do |result|
      {
        golfer:           result.golfer,
        position_display: result.current_position_display,
        score_to_par:     result.current_score_to_par,
        thru:             result.current_thru,
        current_position: result.current_position,
        picks:            picks_by_golfer[result.golfer_id] || [],
        earnings_cents:   result.earnings_cents
      }
    end

    # Fixed sort: earnings desc for active players, then CUT, then WD
    bottom_val = ->(r) {
      case r[:position_display]
      when "WD"  then 2
      when "CUT" then 1
      else 0
      end
    }
    rows.sort_by! do |r|
      [bottom_val.call(r), -(r[:earnings_cents] || 0), r[:current_position] || 9999, r[:golfer].name]
    end
    rows
  end

  def thru_sort_val(thru)
    return 0 if thru.nil?
    thru&.start_with?("F") ? 19 : thru.to_i
  end

  def no_cut_survivors
    User.where(approved: true).where.not(name: "Commissioner").select(&:no_cut_streak_alive?)
  end
end
