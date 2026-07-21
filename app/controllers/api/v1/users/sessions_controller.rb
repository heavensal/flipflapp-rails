# frozen_string_literal: true

module Api
  module V1
    module Users
      class SessionsController < Devise::SessionsController
        respond_to :json
        skip_before_action :verify_authenticity_token
        skip_before_action :authenticate_user!, raise: false

        private

        def respond_with(resource, _opts = {})
          render json: UserSerializer.new(resource).serializable_hash, status: :ok
        end

        def respond_to_on_destroy(*)
          head :no_content
        end
      end
    end
  end
end
