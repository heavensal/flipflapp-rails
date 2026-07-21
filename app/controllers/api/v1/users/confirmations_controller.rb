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
end
