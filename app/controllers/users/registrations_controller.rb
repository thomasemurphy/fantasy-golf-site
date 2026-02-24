class Users::RegistrationsController < Devise::RegistrationsController
  def new
    redirect_to root_path, alert: "Registration is not open."
  end

  def create
    redirect_to root_path, alert: "Registration is not open."
  end

  protected

  def after_inactive_sign_up_path_for(resource)
    new_user_session_path
  end

  def sign_up_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  def account_update_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :current_password)
  end
end
