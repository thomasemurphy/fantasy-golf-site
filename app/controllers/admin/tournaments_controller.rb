class Admin::TournamentsController < Admin::BaseController
  before_action :set_tournament, only: %i[show update sync_field sync_results sync_live earnings update_earnings sync_earnings]

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

  def sync_live
    SyncLiveLeaderboardJob.perform_later(@tournament.id)
    redirect_to admin_tournament_path(@tournament), notice: "Live sync queued."
  end

  def sync_earnings
    SyncTournamentEarningsJob.perform_later(@tournament.id)
    redirect_to admin_tournament_path(@tournament), notice: "Earnings sync queued."
  end

  def earnings
    @results = @tournament.tournament_results
                          .includes(:golfer)
                          .order("current_position ASC NULLS LAST, golfers.name ASC")
    @picks_by_golfer = @tournament.picks.includes(:user).group_by(&:golfer_id)
  end

  def update_earnings
    ApplicationRecord.transaction do
      (params[:earnings] || {}).each do |result_id, dollars|
        next if dollars.blank?
        TournamentResult.find(result_id).update!(earnings_cents: (dollars.to_f * 100).round)
      end

      @tournament.update!(status: "completed") if params[:mark_completed] == "1"

      @tournament.picks.each(&:save!)
    end

    redirect_to admin_tournament_path(@tournament), notice: "Earnings saved and picks updated."
  rescue => e
    redirect_to earnings_admin_tournament_path(@tournament), alert: "Error: #{e.message}"
  end

  private

  def set_tournament
    @tournament = Tournament.find(params[:id])
  end

  def tournament_params
    params.require(:tournament).permit(:name, :start_date, :end_date, :purse_cents,
                                       :tournament_type, :status, :week_number, :picks_locked_at,
                                       :pgatour_id)
  end
end
