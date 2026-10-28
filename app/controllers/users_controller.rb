# frozen_string_literal: true

class UsersController < InertiaController
  skip_before_action :authenticate, only: %i[new create]
  before_action :require_no_authentication, only: %i[new create]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    return redirect_to sign_up_path, inertia: { errors: @user.errors } unless @user.save

    start_session_for(@user)
    send_email_verification
    redirect_to dashboard_path, notice: "Welcome! You have signed up successfully"
  end

  def destroy
    user = Current.user
    return redirect_to settings_profile_path, inertia: { errors: { password_challenge: "Password challenge is invalid" } } unless user.authenticate(params[:password_challenge] || "")

    user.destroy!
    Current.session = nil
    redirect_to root_path, notice: "Your account has been deleted", inertia: { clear_history: true }
  end

  private

  def user_params
    params.permit(:email, :name, :password, :password_confirmation)
  end

  def send_email_verification
    UserMailer.with(user: @user).email_verification.deliver_later
  end
end
