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
      redirect_to standings_path(tab: "live"), flash: { notice: "Leaderboard was just updated. Try again in #{remaining}s." } and return
    end

    SyncTournamentResultsJob.perform_now(tournament.id)
    Rails.cache.write("standings_last_refreshed", Time.current, expires_in: 10.minutes)
    redirect_to standings_path(tab: "live"), flash: { notice: "Leaderboard updated." }
  end

  def index
    @live_tournament = Tournament.find_by(status: "in_progress")
    default_tab = (@live_tournament && params[:tournament_id].blank?) ? "live" : "overall"
    @tab  = params[:tab] || default_tab
    @sort = params[:sort].presence
    @dir  = %w[asc desc].include?(params[:dir]) ? params[:dir] : nil

    @tab = "overall" if @tab == "live" && @live_tournament.nil?

    @completed_tournaments = Tournament.joins(:picks).distinct.order(:week_number)

    if @tab == "live" && @live_tournament
      @live_view = params[:view] == "field" ? "field" : "pool"
      @standings = []
      if @live_view == "field"
        @live_standings  = []
        @field_standings = field_standings(@live_tournament)
      else
        @live_standings  = live_standings(@live_tournament)
        @field_standings = []
      end
    elsif params[:tournament_id].present?
      @tournament = Tournament.find(params[:tournament_id])
      if @tournament.status == "in_progress"
        redirect_to standings_path(tab: "live") and return
      end
      @t_view = params[:view] == "field" ? "field" : "pool"
      if @t_view == "field"
        @standings = []
        @field_standings = field_standings(@tournament)
      else
        @standings = tournament_standings(@tournament)
        @field_standings = []
      end
      @live_standings = []
    else
      @standings = compute_standings(@tab)
      @live_standings = []
    end

    @no_cut_users = no_cut_survivors
    @last_refreshed = Rails.cache.read("standings_last_refreshed")
  end

  private

  def compute_standings(tab)
    users = User.where(approved: true).where.not(name: "Commissioner")
                .includes(picks: [:golfer, :tournament])

    completed_tid = Tournament.where(status: "completed").pluck(:id)
    results_index = TournamentResult.where(tournament_id: completed_tid)
                                    .index_by { |r| [r.tournament_id, r.golfer_id] }

    sorted = users.sort_by { |u| [-earnings_for_tab(u, tab), u.name] }

    rank = 1
    sorted.chunk_while { |a, b| earnings_for_tab(a, tab) == earnings_for_tab(b, tab) }.flat_map do |group|
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
        { rank: display, user: user, earnings_cents: earnings_for_tab(user, tab), completed_picks: completed_picks, total_earnings_cents: total_earnings }
      end
    end
  end

  def tournament_standings(tournament)
    sort = @sort || "earnings"
    dir  = @dir  || "desc"

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

    # --- Compute earnings-based display rank, independent of current sort ---
    cut_val = ->(p) { p.current_position_display == "CUT" ? 1 : 0 }
    by_earnings = picks.sort_by { |p| [cut_val.call(p), -(p.earnings_cents || 0), p.current_position || 9999, p.golfer.name, p.user.name] }

    rank_by_id = {}
    rank = 1
    by_earnings.chunk_while { |a, b|
      cut_val.call(a) == cut_val.call(b) && (a.earnings_cents || 0) == (b.earnings_cents || 0)
    }.each do |group|
      if cut_val.call(group.first) == 1
        group.each { |p| rank_by_id[p.id] = "—" }
      else
        display = group.size > 1 ? "T#{rank}" : rank.to_s
        group.each { |p| rank_by_id[p.id] = display }
        rank += group.size
      end
    end

    # --- Sort rows by user-selected column ---
    picks.sort_by! do |p|
      cut = p.current_position_display == "CUT" ? 1 : 0
      case sort
      when "player"   then [p.user.name]
      when "golfer"   then [p.golfer.name]
      when "pos"      then [cut, p.current_position || 9999, p.golfer_id, p.user.name]
      when "earnings"
        base = p.earnings_cents || 0
        earnings_val = dir == "desc" ? -base : base
        [cut, earnings_val, p.current_position || 9999, p.golfer.name, p.user.name]
      else # score
        [cut, p.current_position || 9999, p.golfer.name, p.user.name]
      end
    end

    picks.reverse! if %w[player golfer].include?(sort) && dir == "desc"
    if dir == "desc" && sort == "score"
      picks.reverse!
      picks.sort_by!.with_index { |p, i| [p.current_position_display == "CUT" ? 1 : 0, i] }
    end

    picks.map do |pick|
      {
        rank:                  rank_by_id[pick.id] || "—",
        user:                  pick.user,
        golfer:                pick.golfer,
        pick:                  pick,
        position_display:      pick.current_position_display,
        score_to_par:          pick.current_score_to_par,
        earnings_cents:        pick.earnings_cents,
        completed_picks:       history_by_user[pick.user_id] || [],
        total_earnings_cents:  total_earnings_by_user[pick.user_id] || 0
      }
    end
  end

  def earnings_for_tab(user, tab)
    case tab
    when "majors" then user.majors_earnings_cents
    when "side_events" then user.side_events_earnings_cents
    when "first_half" then user.first_half_earnings_cents
    when "second_half" then user.second_half_earnings_cents
    else user.total_earnings_cents
    end
  end

  def live_standings(tournament)
    sort = @sort || "score"
    dir  = @dir  || "asc"

    picks = Pick.where(tournament: tournament)
                .joins("LEFT JOIN tournament_results ON tournament_results.tournament_id = picks.tournament_id AND tournament_results.golfer_id = picks.golfer_id")
                .select("picks.*, " \
                        "tournament_results.current_position, tournament_results.current_position_display, " \
                        "tournament_results.current_score_to_par, tournament_results.current_thru, " \
                        "tournament_results.current_round, tournament_results.current_earnings_cents")
                .preload(:user, :golfer)
                .to_a

    picks.sort_by! do |p|
      cut = p.current_position_display == "CUT" ? 1 : 0
      case sort
      when "player"   then [cut, p.user.name]
      when "golfer"   then [cut, p.golfer.name]
      when "pos"      then [cut, p.current_position || 9999, p.user.name]
      when "thru"     then [cut, thru_sort_val(p.current_thru), p.user.name]
      when "earnings" then [cut, p.current_earnings_cents || 0, p.user.name]
      else # "score" (default)
        [cut, p.current_score_to_par || 999, p.user.name]
      end
    end
    picks.reverse! if dir == "desc"
    # After reversing, CUT players would move to the top — put them back at the bottom
    picks.sort_by!.with_index { |p, i| [p.current_position_display == "CUT" ? 1 : 0, i] } if dir == "desc"

    picks.map.with_index(1) do |pick, rank|
      {
        rank:                    rank,
        user:                    pick.user,
        golfer:                  pick.golfer,
        pick:                    pick,
        position_display:        pick.current_position_display,
        score_to_par:            pick.current_score_to_par,
        thru:                    pick.current_thru,
        current_earnings_cents:  pick.current_earnings_cents
      }
    end
  end

  def field_standings(tournament)
    sort = @sort || "score"
    dir  = @dir  || "asc"

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

    rows.sort_by! do |r|
      cut = r[:position_display] == "CUT" ? 1 : 0
      case sort
      when "golfer" then [cut, r[:golfer].name]
      when "pos"    then [cut, r[:current_position] || 9999, r[:golfer].name]
      when "thru"   then [cut, thru_sort_val(r[:thru]), r[:golfer].name]
      else               [cut, r[:score_to_par] || 999, r[:golfer].name]
      end
    end
    rows.reverse! if dir == "desc"
    # After reversing, CUT players would move to the top — put them back at the bottom
    rows.sort_by!.with_index { |r, i| [r[:position_display] == "CUT" ? 1 : 0, i] } if dir == "desc"
    rows
  end

  def thru_sort_val(thru)
    return -1 if thru.nil?
    thru == "F" ? 18 : thru.to_i
  end

  def no_cut_survivors
    User.where(approved: true).where.not(name: "Commissioner").select(&:no_cut_streak_alive?)
  end
end
