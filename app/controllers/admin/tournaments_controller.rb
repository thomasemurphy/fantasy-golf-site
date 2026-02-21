class Admin::TournamentsController < Admin::BaseController
  before_action :set_tournament, only: %i[show update sync_field sync_results]

  def index
    @tournaments = Tournament.order(:week_number)
  end

  def show
    @picks = @tournament.picks.includes(:user, :golfer).order("users.name")
  end

  def update
    if @tournament.update(tournament_params)
      redirect_to admin_tournament_path(@tournament), notice: "Tournament updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def sync_field
    SyncTournamentFieldJob.perform_later(@tournament.id)
    redirect_to admin_tournament_path(@tournament), notice: "Field sync queued."
  end

  def sync_results
    SyncTournamentResultsJob.perform_later(@tournament.id)
    redirect_to admin_tournament_path(@tournament), notice: "Results sync queued."
  end

  private

  def set_tournament
    @tournament = Tournament.find(params[:id])
  end

  def tournament_params
    params.require(:tournament).permit(:name, :start_date, :end_date, :purse_cents,
                                       :tournament_type, :status, :week_number, :picks_locked_at)
  end
end
