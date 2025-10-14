module Api
  module V1
    class SessionsController < ApplicationController
      skip_before_action :authenticate_user!, only: [ :create ]

      # sign in -> Devise will issue JWT token in response Authorization header
      def create
        user = User.find_for_database_authentication(email: params[:user][:email])
        if user&.valid_password?(params[:user][:password])
          sign_in user
          # devise-jwt will add `Authorization` header with Bearer token automatically
          render json: { user: { id: user.id, email: user.email } }, status: :ok
        else
          render json: { error: "Invalid email or password" }, status: :unauthorized
        end
      end

      # sign out -> revoke token via JwtDenylist (configured in devise initializer)
      def destroy
        # Devise + devise-jwt will handle revocation automatically for requests matching revocation_requests
        # If you want to be explicit:
        current_user && sign_out(current_user)
        head :no_content
      end
    end
  end
end
