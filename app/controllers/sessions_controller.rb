# frozen_string_literal: true

class SessionsController < InertiaController
  skip_before_action :authenticate, only: %i[new create]
  before_action :require_no_authentication, only: %i[new create]
  before_action :set_session, only: :destroy

  def new
  end

  def create
    user = User.authenticate_by(email: params[:email], password: params[:password])
    return redirect_to sign_in_path, alert: "That email or password is incorrect" unless user

    start_session_for(user)
    redirect_to dashboard_path, notice: "Signed in successfully"
  end

  def destroy
    @session.destroy!
    Current.session = nil
    redirect_to settings_sessions_path, notice: "That session has been logged out", inertia: { clear_history: true }
  end

  private

  def set_session
    @session = Current.user.sessions.find(params[:id])
  end
end
