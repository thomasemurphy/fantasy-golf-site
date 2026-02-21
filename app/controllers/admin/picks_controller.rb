class Admin::PicksController < Admin::BaseController
  def index
    @tournament = Tournament.where(status: %w[upcoming in_progress])
                            .order(:start_date).first
    @tournament ||= Tournament.order(start_date: :desc).first

    if @tournament
      @picks_by_user = @tournament.picks.includes(:user, :golfer).order("users.name")
      @users_without_picks = User.where(approved: true)
                                 .where.not(id: @tournament.picks.select(:user_id))
                                 .order(:name)
    end
  end

  def show
    @pick = Pick.includes(:user, :tournament, :golfer).find(params[:id])
  end
end
