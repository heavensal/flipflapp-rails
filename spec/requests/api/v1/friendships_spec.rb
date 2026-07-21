# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1 Friendships", type: :request do
  describe "GET /api/v1/friendships" do
    it "returns friendship buckets" do
      user = create(:user)
      friend = create(:user)
      create(:friendship, sender: user, receiver: friend, status: "accepted")

      api_get "/api/v1/friendships", user: user

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.keys).to match_array(%w[accepted sent received declined])
      expect(body["accepted"].length).to eq(1)
    end
  end

  describe "POST /api/v1/friendships" do
    it "creates a pending friendship" do
      user = create(:user)
      other = create(:user)

      expect {
        api_post "/api/v1/friendships", user: user, params: { user_id: other.id }
      }.to change(Friendship, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["status"]).to eq("pending")
    end
  end

  describe "PATCH /api/v1/friendships/:id" do
    it "accepts a pending request as receiver" do
      sender = create(:user)
      receiver = create(:user)
      friendship = create(:friendship, sender: sender, receiver: receiver, status: "pending")

      api_patch "/api/v1/friendships/#{friendship.id}", user: receiver, params: { status: "accepted" }

      expect(response).to have_http_status(:ok)
      expect(friendship.reload.status).to eq("accepted")
    end
  end

  describe "GET /api/v1/friendships/search" do
    it "searches users without friendship" do
      user = create(:user)
      other = create(:user, first_name: "Zinedine", last_name: "Zidane", username: "zizou#0001")

      api_get "/api/v1/friendships/search", user: user, params: { q: { first_name_or_last_name_or_username_cont: "Zinedine" } }

      expect(response).to have_http_status(:ok)
      result = JSON.parse(response.body).find { |search_user| search_user["id"] == other.id }
      expect(result).to include(
        "first_name" => other.first_name,
        "last_name" => other.last_name,
        "username" => other.username
      )
      expect(result).not_to include("email", "role")
    end
  end
end
