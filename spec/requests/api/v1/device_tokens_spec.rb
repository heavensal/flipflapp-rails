# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1 Device Tokens", type: :request do
  describe "POST /api/v1/device_token" do
    it "registers a device token for the current user" do
      user = create(:user)

      api_post "/api/v1/device_token",
        user: user,
        params: { device_token: { token: "fcm-abc", platform: "android" } }

      expect(response).to have_http_status(:ok)
      expect(user.device_tokens.find_by(token: "fcm-abc").platform).to eq("android")
    end

    it "defaults platform to android" do
      user = create(:user)

      api_post "/api/v1/device_token",
        user: user,
        params: { device_token: { token: "fcm-def" } }

      expect(response).to have_http_status(:ok)
      expect(user.device_tokens.find_by!(token: "fcm-def").platform).to eq("android")
    end

    it "rejects unknown platforms" do
      user = create(:user)

      api_post "/api/v1/device_token",
        user: user,
        params: { device_token: { token: "fcm-ghi", platform: "web" } }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /api/v1/device_token" do
    it "removes the current user's device token" do
      user = create(:user)
      create(:device_token, user: user, token: "fcm-xyz")

      api_delete "/api/v1/device_token",
        user: user,
        params: { device_token: { token: "fcm-xyz" } }

      expect(response).to have_http_status(:no_content)
      expect(user.device_tokens.find_by(token: "fcm-xyz")).to be_nil
    end

    it "is idempotent when the token is missing" do
      user = create(:user)

      api_delete "/api/v1/device_token",
        user: user,
        params: { device_token: { token: "missing" } }

      expect(response).to have_http_status(:no_content)
    end
  end
end
