# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1 Me updates", type: :request do
  describe "email reconfirmable" do
    it "keeps login email and exposes unconfirmed_email on CurrentUser" do
      user = create(:user, email: "old@example.com")
      api_patch "/api/v1/me", user: user, params: { user: { email: "new@example.com" } }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["email"]).to eq("old@example.com")
      expect(body["unconfirmed_email"]).to eq("new@example.com")
      user.reload
      expect(user.email).to eq("old@example.com")
      expect(user.unconfirmed_email).to eq("new@example.com")
    end
  end

  describe "username and role" do
    it "ignores username and role in strong params" do
      user = create(:user, first_name: "Ada", last_name: "Lovelace")
      original_username = user.username

      api_patch "/api/v1/me", user: user, params: {
        user: { first_name: "Ada", username: "hacked#9999", role: "admin" }
      }

      expect(response).to have_http_status(:ok)
      user.reload
      expect(user.username).to eq(original_username)
      expect(user.role).to eq("player")
      expect(JSON.parse(response.body)["username"]).to eq(original_username)
    end
  end

  describe "password" do
    it "updates password without current_password and keeps JWT valid" do
      user = create(:user, password: "password123", password_confirmation: "password123")
      headers = api_auth_headers_for(user)

      patch "/api/v1/me",
            params: {
              user: { password: "newpass99", password_confirmation: "newpass99" }
            },
            headers: headers,
            as: :json

      expect(response).to have_http_status(:ok)
      get "/api/v1/me", headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(user.reload.valid_password?("newpass99")).to be(true)
    end

    it "returns 422 when password confirmation does not match" do
      user = create(:user)
      api_patch "/api/v1/me", user: user, params: {
        user: { password: "newpass99", password_confirmation: "other99" }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      details = JSON.parse(response.body).dig("error", "details")
      expect(details["password_confirmation"]).to be_present
    end

    it "returns 422 when password is too short" do
      user = create(:user)
      api_patch "/api/v1/me", user: user, params: {
        user: { password: "short", password_confirmation: "short" }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      details = JSON.parse(response.body).dig("error", "details")
      expect(details["password"].join).to include("trop court")
    end
  end

  describe "names" do
    it "returns 422 when first_name is blank" do
      user = create(:user)
      api_patch "/api/v1/me", user: user, params: { user: { first_name: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
      details = JSON.parse(response.body).dig("error", "details")
      expect(details["first_name"].join).to include("prénom")
    end
  end

  describe "avatar multipart" do
    it "uploads avatar via multipart and returns avatar_url" do
      stub_cloudinary_upload!
      user = create(:user)
      headers = api_auth_headers_for(user)

      patch "/api/v1/me",
            params: {
              user: { avatar: fixture_file_upload("files/avatar.jpg", "image/jpeg") }
            },
            headers: headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["avatar_url"]).to be_present
      expect(user.reload.avatar?).to be(true)
    end

    it "rejects invalid avatar extension with French details" do
      stub_cloudinary_upload!
      user = create(:user)
      headers = api_auth_headers_for(user)

      patch "/api/v1/me",
            params: {
              user: { avatar: fixture_file_upload("files/avatar.txt", "text/plain") }
            },
            headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      details = JSON.parse(response.body).dig("error", "details")
      expect(details["avatar"].join).to include("format")
    end

    it "clears avatar with remove_avatar" do
      stub_cloudinary_upload!
      user = create(:user)
      user.update!(avatar: fixture_file_upload("files/avatar.jpg", "image/jpeg"))
      expect(user.reload.avatar?).to be(true)

      api_patch "/api/v1/me", user: user, params: { user: { remove_avatar: true } }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["avatar_url"]).to be_nil
      expect(user.reload.avatar?).to be(false)
    end
  end
end
