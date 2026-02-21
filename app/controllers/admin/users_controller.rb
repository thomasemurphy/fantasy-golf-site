class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: %i[show update approve toggle_paid]

  def index
    @pending_users = User.where(approved: false).order(:created_at)
    @approved_users = User.where(approved: true).order(:name)
  end

  def show
    @picks = @user.picks.includes(:tournament, :golfer).order("tournaments.start_date desc")
  end

  def update
    if @user.update(user_params)
      redirect_to admin_user_path(@user), notice: "User updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def approve
    @user.update!(approved: true)
    redirect_to admin_users_path, notice: "#{@user.name} approved."
  end

  def toggle_paid
    @user.update!(entry_paid: !@user.entry_paid)
    redirect_to admin_users_path, notice: "Entry fee status updated for #{@user.name}."
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :admin, :approved, :entry_paid, :double_downs_remaining)
  end
end
