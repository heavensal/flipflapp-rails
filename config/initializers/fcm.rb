# frozen_string_literal: true

module Flipflapp
  module FcmConfig
    module_function

    def configured?
      project_id.present? && service_account_json.present?
    end

    def project_id
      env_value("FCM_PROJECT_ID")
    end

    def service_account_json
      raw = env_value("FCM_SERVICE_ACCOUNT_JSON")
      return unless raw

      normalize_service_account_json(raw)
    end

    # Secret managers / Docker env injection often turn PEM newlines into literal "\n".
    # googleauth + OpenSSL need real line breaks in private_key.
    def normalize_service_account_json(raw)
      data = JSON.parse(raw)
      private_key = data["private_key"]
      return raw unless private_key.is_a?(String) && private_key.include?("\\n")

      data["private_key"] = private_key.gsub("\\n", "\n")
      data.to_json
    rescue JSON::ParserError
      raw
    end
    private_class_method :normalize_service_account_json

    # Strip optional surrounding quotes from .env / secret managers.
    def env_value(name)
      value = ENV[name].to_s.strip
      if (value.start_with?('"') && value.end_with?('"')) ||
          (value.start_with?("'") && value.end_with?("'"))
        value = value[1..-2].to_s.strip
      end
      value.presence
    end
    private_class_method :env_value
  end
end
