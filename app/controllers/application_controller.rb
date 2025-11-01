class ApplicationController < ActionController::API
  include ActionController::MimeResponds
  before_action :authenticate_user!

  # Handle token decode / expiration errors coming from the jwt gem
  rescue_from JWT::ExpiredSignature, JWT::DecodeError, with: :render_unauthorized

  private

  def render_unauthorized(exception = nil)
    render json: { error: "Unauthorized", message: exception&.message }, status: :unauthorized
  end
end
