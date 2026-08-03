# frozen_string_literal: true

class DeviseApiFailureApp < Devise::FailureApp
  def http_auth_body
    return super unless request_format == :json

    { error: { message: i18n_message } }.to_json
  end
end
