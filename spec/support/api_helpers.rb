# frozen_string_literal: true

module ApiHelpers
  def api_auth_headers_for(user, password: "password123")
    post "/api/v1/users/sign_in",
         params: { user: { email: user.email, password: password } },
         as: :json

    auth = response.headers["Authorization"]
    raise "JWT missing for #{user.email}: #{response.status} #{response.body}" if auth.blank?

    { "Authorization" => auth }
  end

  def api_get(path, user:, params: nil, headers: {})
    get path, params: params, headers: api_auth_headers_for(user).merge(headers), as: :json
  end

  def api_post(path, user:, params: nil, headers: {})
    post path, params: params, headers: api_auth_headers_for(user).merge(headers), as: :json
  end

  def api_patch(path, user:, params: nil, headers: {})
    patch path, params: params, headers: api_auth_headers_for(user).merge(headers), as: :json
  end

  def api_delete(path, user:, params: nil, headers: {})
    delete path, params: params, headers: api_auth_headers_for(user).merge(headers), as: :json
  end
end

RSpec.configure do |config|
  config.include ApiHelpers, type: :request
end
