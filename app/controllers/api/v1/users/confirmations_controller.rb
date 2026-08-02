# frozen_string_literal: true

module Api
  module V1
    module Users
      class ConfirmationsController < Devise::ConfirmationsController
        respond_to :json
        skip_before_action :verify_authenticity_token

        def create
          self.resource = resource_class.send_confirmation_instructions(resource_params)
          if successfully_sent?(resource)
            head :no_content
          else
            render_confirmation_validation_errors
          end
        end

        def update
          self.resource = resource_class.confirm_by_token(confirmation_token_param)
          if resource.errors.empty?
            sign_in(resource_name, resource)
            render json: CurrentUserSerializer.new(resource).serializable_hash, status: :ok
          else
            render_confirmation_validation_errors
          end
        end

        private

        def confirmation_token_param
          params.dig(:user, :confirmation_token).presence || params[:confirmation_token]
        end

        def render_confirmation_validation_errors
          render json: {
            error: {
              message: "Validation failed",
              details: resource.errors.to_hash(true)
            }
          }, status: :unprocessable_entity
        end
      end
    end
  end
end
