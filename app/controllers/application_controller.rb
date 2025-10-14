class ApplicationController < ActionController::API
  include ActionController::MimeResponds
  before_action :authenticate_user!

  # Optional: handle unauthenticated JSON response
  rescue_from Devise::JWT::RevocationStrategies::Denylist::RevokedToken, with: :render_unauthorized

  private

  def render_unauthorized
    render json: { error: "Unauthorized" }, status: :unauthorized
  end
end
