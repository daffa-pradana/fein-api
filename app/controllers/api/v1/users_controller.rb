module Api
  module V1
    class UsersController < ApplicationController
      before_action :authenticate_user!

      # GET /api/v1/me
      def show
        render json: { user: user_json(current_user) }, status: :ok
      end

      # PATCH /api/v1/me
      # For non-sensitive profile fields only.
      def update
        if current_user.update(profile_params)
          render json: { user: user_json(current_user) }, status: :ok
        else
          render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/me/email
      # Require current_password to change email (safer).
      def update_email
        unless params[:current_password].present?
          return render json: { error: "current_password is required" }, status: :unauthorized
        end

        unless current_user.valid_password?(params[:current_password])
          return render json: { error: "current password is incorrect" }, status: :unauthorized
        end

        if current_user.update(email: params[:email])
          # If Devise confirmable is enabled, Devise will send confirmation to new email.
          render json: { user: user_json(current_user) }, status: :ok
        else
          render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/me/password
      # Require current_password; update_with_password ensures current_password is checked.
      def update_password
        # Using Devise's update_with_password helper expects params in a specific shape.
        update_params = {
          current_password: params[:current_password],
          password: params[:password],
          password_confirmation: params[:password_confirmation]
        }

        if current_user.update_with_password(update_params)
          # Optionally sign in the user again (warden) if you want to dispatch a new token:
          request.env["warden"].set_user(current_user, store: false)
          render json: { user: user_json(current_user) }, status: :ok
        else
          render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def profile_params
        params.require(:user).permit(:first_name, :last_name)
      end

      def user_json(user)
        {
          id: user.id,
          email: user.email,
          first_name: user.first_name,
          last_name: user.last_name
        }
      end
    end
  end
end
