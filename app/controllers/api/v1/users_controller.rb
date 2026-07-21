# frozen_string_literal: true

module Api
  module V1
    class UsersController < BaseController
      def me
        render json: UserSerializer.new(current_user).serializable_hash
      end

      def show
        user = User.find(params[:id])
        render json: UserSerializer.new(user).serializable_hash
      end

      def update
        if current_user.update(user_params)
          render json: UserSerializer.new(current_user).serializable_hash
        else
          render_validation_errors(current_user)
        end
      end

      private

      def user_params
        params.require(:user).permit(:first_name, :last_name, :avatar, :email, :password, :password_confirmation)
      end
    end
  end
end
