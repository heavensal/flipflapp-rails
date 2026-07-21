# frozen_string_literal: true

module Api
  module V1
    module Users
      class RegistrationsController < Devise::RegistrationsController
        respond_to :json
        skip_before_action :verify_authenticity_token
        before_action :configure_sign_up_params, only: :create

        private

        def respond_with(resource, _opts = {})
          if resource.persisted?
            render json: UserSerializer.new(resource).serializable_hash, status: :created
          else
            render json: {
              error: {
                message: "Validation failed",
                details: resource.errors.to_hash(true)
              }
            }, status: :unprocessable_entity
          end
        end

        def configure_sign_up_params
          devise_parameter_sanitizer.permit(:sign_up, keys: [ :first_name, :last_name, :avatar ])
        end
      end
    end
  end
end
