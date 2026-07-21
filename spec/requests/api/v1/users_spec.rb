# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1 Users", type: :request do
  describe "POST /api/v1/users" do
    it "registers a user" do
      expect {
        post "/api/v1/users", params: {
          user: {
            email: "new.player@example.com",
            password: "password123",
            password_confirmation: "password123",
            first_name: "Ada",
            last_name: "Lovelace"
          }
        }, as: :json
      }.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)).to include("email" => "new.player@example.com", "first_name" => "Ada")
    end
  end

  describe "GET /api/v1/me" do
    it "returns the current user" do
      user = create(:user)
      api_get "/api/v1/me", user: user

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include("id" => user.id, "email" => user.email)
    end

    it "rejects unauthenticated requests" do
      get "/api/v1/me", as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH /api/v1/me" do
    it "updates the current user profile" do
      user = create(:user)
      api_patch "/api/v1/me", user: user, params: { user: { first_name: "Updated" } }

      expect(response).to have_http_status(:ok)
      expect(user.reload.first_name).to eq("Updated")
    end
  end

  describe "GET /api/v1/users/:id" do
    it "returns the user" do
      user = create(:user)
      other = create(:user)
      api_get "/api/v1/users/#{other.id}", user: user

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include("id" => other.id)
    end
  end
end
