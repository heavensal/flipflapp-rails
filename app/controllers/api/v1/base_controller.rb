# frozen_string_literal: true

module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_user!

      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

      private

      def render_error(message, status, details: nil)
        payload = { error: { message: message } }
        payload[:error][:details] = details if details.present?
        render json: payload, status: status
      end

      def render_not_found
        render_error("Not found", :not_found)
      end

      def render_forbidden(message = "Forbidden")
        render_error(message, :forbidden)
      end

      def render_validation_errors(record)
        render_error(
          "Validation failed",
          :unprocessable_entity,
          details: record.errors.to_hash(true)
        )
      end
    end
  end
end
