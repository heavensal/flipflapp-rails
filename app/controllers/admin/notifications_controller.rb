module Admin
  class NotificationsController < BaseController
    include Resourceful
    admin_resource :notifications

    private

    def resource_params
      permitted = super
      parse_json_attribute(permitted, :payload)
      permitted
    end

    def parse_json_attribute(permitted, key)
      return unless permitted[key].is_a?(String)

      permitted[key] = JSON.parse(permitted[key])
    rescue JSON::ParserError
      permitted
    end
  end
end
