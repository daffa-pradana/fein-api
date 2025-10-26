module Api
  module V1
    class SessionsController < ApplicationController
      skip_before_action :authenticate_user!, only: [ :create ]

      def create
        user = User.find_for_database_authentication(email: params[:email])
        if user&.valid_password?(params[:password])
          warden.set_user(user, store: false)
          render json: { user: { id: user.id, email: user.email } }, status: :ok
        else
          render json: { error: "Invalid email or password" }, status: :unauthorized
        end
      end

      def destroy
        warden.logout(:user) if current_user
        head :no_content
      end
    end
  end
end
