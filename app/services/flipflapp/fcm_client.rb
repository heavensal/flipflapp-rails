# frozen_string_literal: true

require "googleauth"
require "net/http"

module Flipflapp
  class FcmClient
    SCOPE = "https://www.googleapis.com/auth/firebase.messaging"
    UNREGISTERED_CODES = %w[UNREGISTERED NOT_FOUND INVALID_ARGUMENT].freeze

    class Error < StandardError
      attr_reader :status, :error_code

      def initialize(message, status:, error_code: nil)
        super(message)
        @status = status
        @error_code = error_code
      end

      def unregistered?
        status == 404 || UNREGISTERED_CODES.include?(error_code.to_s)
      end
    end

    def initialize(config: Flipflapp::FcmConfig)
      @config = config
    end

    def send_message(token:, title:, body:, data: {})
      raise Error.new("FCM is not configured", status: 0) unless @config.configured?

      uri = URI("https://fcm.googleapis.com/v1/projects/#{@config.project_id}/messages:send")
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{access_token}"
      request["Content-Type"] = "application/json; charset=utf-8"
      request.body = JSON.generate(
        message: {
          token: token,
          notification: { title: title, body: body },
          data: stringify_data(data),
          android: {
            priority: "HIGH",
            notification: {
              channel_id: "flipflapp_notifications"
            }
          }
        }
      )

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      return if response.is_a?(Net::HTTPSuccess)

      payload = parse_json(response.body)
      error_code = payload.dig("error", "details", 0, "errorCode") ||
        payload.dig("error", "status")

      raise Error.new(
        payload.dig("error", "message") || "FCM delivery failed (#{response.code})",
        status: response.code.to_i,
        error_code: error_code
      )
    end

    private

    def access_token
      credentials = Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: StringIO.new(@config.service_account_json),
        scope: SCOPE
      )
      credentials.fetch_access_token!["access_token"]
    end

    def stringify_data(data)
      data.to_h.transform_keys(&:to_s).transform_values { |value| value.nil? ? "" : value.to_s }
    end

    def parse_json(body)
      JSON.parse(body.to_s)
    rescue JSON::ParserError
      {}
    end
  end
end
