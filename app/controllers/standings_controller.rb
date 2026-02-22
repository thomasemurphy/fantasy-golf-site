class StandingsController < ApplicationController
  def index
    @tab = params[:tab] || "overall"
    @completed_tournaments = Tournament.joins(:picks).distinct.order(:week_number)

    if params[:tournament_id].present?
      @tournament = Tournament.find(params[:tournament_id])
      @standings = tournament_standings(@tournament)
    else
      @standings = compute_standings(@tab)
    end

    @no_cut_users = no_cut_survivors
  end

  private

  def compute_standings(tab)
    users = User.where(approved: true).includes(:picks)

    ranked = case tab
    when "majors"
      users.sort_by { |u| -u.majors_earnings_cents }
    when "side_events"
      users.sort_by { |u| -u.side_events_earnings_cents }
    when "first_half"
      users.sort_by { |u| -u.first_half_earnings_cents }
    when "second_half"
      users.sort_by { |u| -u.second_half_earnings_cents }
    else
      users.sort_by { |u| -u.total_earnings_cents }
    end

    ranked.map.with_index(1) do |user, rank|
      {
        rank: rank,
        user: user,
        earnings_cents: earnings_for_tab(user, tab)
      }
    end
  end

  def tournament_standings(tournament)
    picks = Pick.where(tournament: tournament)
                .includes(:user, :golfer)
                .order(earnings_cents: :desc)

    picks.map.with_index(1) do |pick, rank|
      {
        rank: rank,
        user: pick.user,
        golfer: pick.golfer,
        pick: pick,
        earnings_cents: pick.earnings_cents
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

  def no_cut_survivors
    User.where(approved: true).select(&:no_cut_streak_alive?)
  end
end
