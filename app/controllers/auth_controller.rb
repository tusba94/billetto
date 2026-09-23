class AuthController < ApplicationController
  def index
    redirect_to events_path if clerk&.user?
  end

  def me
    return head :unauthorized unless clerk&.user?

    render json: { user_id: clerk.user_id }
  end

  def sign_up
  redirect_to events_path if clerk&.user?
  end
end