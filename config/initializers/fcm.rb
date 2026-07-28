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
      env_value("FCM_SERVICE_ACCOUNT_JSON")
    end

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
