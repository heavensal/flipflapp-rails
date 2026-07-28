# frozen_string_literal: true

module Flipflapp
  module WebPushConfig
    module_function

    def configured?
      public_key.present? && private_key.present?
    end

    def public_key
      env_value("VAPID_PUBLIC_KEY")
    end

    def private_key
      env_value("VAPID_PRIVATE_KEY")
    end

    def subject
      env_value("VAPID_SUBJECT") || "mailto:hello@flipflapp.fr"
    end

    def vapid_options
      {
        subject: subject,
        public_key: public_key,
        private_key: private_key
      }
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
