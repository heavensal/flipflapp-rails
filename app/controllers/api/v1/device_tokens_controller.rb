# frozen_string_literal: true

module Api
  module V1
    class DeviceTokensController < BaseController
      def create
        device_token = DeviceToken.register_for(
          current_user,
          token: device_token_params[:token],
          platform: device_token_params[:platform].presence || "android"
        )

        if device_token.save
          head :ok
        else
          render_validation_errors(device_token)
        end
      end

      def destroy
        device_token = current_user.device_tokens.find_by(token: device_token_params[:token])
        device_token&.destroy!
        head :no_content
      end

      private

      def device_token_params
        params.require(:device_token).permit(:token, :platform)
      end
    end
  end
end
