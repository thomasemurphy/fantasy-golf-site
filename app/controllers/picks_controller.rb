class PicksController < ApplicationController
  before_action :set_current_tournament, only: %i[index create]

  def index
    @current_pick = current_user.picks.find_by(tournament: @current_tournament) if @current_tournament
    @available_golfers = available_golfers_for_current_tournament if @current_tournament
    @past_picks = current_user.picks
                              .eager_load(:tournament, :golfer)
                              .where(tournaments: { status: "completed" })
                              .order("tournaments.start_date desc")
  end

  def create
    if @current_tournament.nil?
      redirect_to picks_path, alert: "No active tournament."
      return
    end

    if @current_tournament.picks_locked?
      redirect_to picks_path, alert: "Picks are locked for this tournament."
      return
    end

    if current_user.picks.exists?(tournament: @current_tournament)
      redirect_to picks_path, alert: "You already have a pick for this tournament."
      return
    end

    @pick = current_user.picks.build(pick_params.merge(tournament: @current_tournament))

    if @pick.save
      if @pick.is_double_down?
        current_user.decrement!(:double_downs_remaining)
      end
      redirect_to picks_path, notice: "Pick submitted: #{@pick.golfer.name}#{' (double-down)' if @pick.is_double_down?}"
    else
      @available_golfers = available_golfers_for_current_tournament
      @past_picks = current_user.picks
                                .eager_load(:tournament, :golfer)
                                .where(tournaments: { status: "completed" })
                                .order("tournaments.start_date desc")
      flash.now[:alert] = @pick.errors.full_messages.to_sentence
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    pick = current_user.picks.find(params[:id])
    tournament = pick.tournament

    if tournament.picks_locked?
      redirect_to picks_path, alert: "Cannot change pick after the deadline."
      return
    end

    if pick.is_double_down?
      current_user.increment!(:double_downs_remaining)
    end

    pick.destroy
    redirect_to picks_path, notice: "Pick cleared — choose a new golfer below."
  end

  private

  def set_current_tournament
    @current_tournament = Tournament.where(status: %w[upcoming in_progress])
                                    .order(:start_date)
                                    .first
  end

  def pick_params
    params.require(:pick).permit(:golfer_id, :is_double_down)
  end

  def available_golfers_for_current_tournament
    used_ids = current_user.used_golfer_ids
    @current_tournament.golfers.where.not(id: used_ids).order(:name)
  end
end
