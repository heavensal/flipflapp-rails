# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1 Device Tokens", type: :request do
  describe "POST /api/v1/device_token" do
    it "registers a device token for the current user with 200 empty body" do
      user = create(:user)

      api_post "/api/v1/device_token",
        user: user,
        params: { device_token: { token: "fcm-abc", platform: "android" } }

      expect(response).to have_http_status(:ok)
      expect(response.body).to be_blank
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

    it "accepts ios platform" do
      user = create(:user)

      api_post "/api/v1/device_token",
        user: user,
        params: { device_token: { token: "fcm-ios", platform: "ios" } }

      expect(response).to have_http_status(:ok)
      expect(user.device_tokens.find_by!(token: "fcm-ios").platform).to eq("ios")
    end

    it "reassigns an existing token to the current user" do
      previous = create(:user)
      current = create(:user)
      create(:device_token, user: previous, token: "shared-fcm", platform: "android")

      api_post "/api/v1/device_token",
        user: current,
        params: { device_token: { token: "shared-fcm", platform: "android" } }

      expect(response).to have_http_status(:ok)
      expect(DeviceToken.find_by!(token: "shared-fcm").user_id).to eq(current.id)
      expect(previous.device_tokens.find_by(token: "shared-fcm")).to be_nil
    end

    it "rejects unknown platforms" do
      user = create(:user)

      api_post "/api/v1/device_token",
        user: user,
        params: { device_token: { token: "fcm-ghi", platform: "web" } }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "requires authentication" do
      post "/api/v1/device_token",
           params: { device_token: { token: "fcm-noauth" } },
           as: :json

      expect(response).to have_http_status(:unauthorized)
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
