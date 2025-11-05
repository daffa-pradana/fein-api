module Api
  module V1
    class RegistrationsController < ApplicationController
      skip_before_action :authenticate_user!, only: [ :create ]

      def create
        user = User.new(sign_up_params)
        if user.save
          render json: { user: { id: user.id, email: user.email } }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def sign_up_params
        params.require(:user).permit(
          :email,
          :password,
          :password_confirmation,
          :first_name,
          :last_name,
        )
      end
    end
  end
end
