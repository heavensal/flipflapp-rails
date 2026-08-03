# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1 Friendships", type: :request do
  describe "GET /api/v1/friendships" do
    it "returns all four buckets with nested PublicUser shapes" do
      user = create(:user)
      friend = create(:user, first_name: "Ada", last_name: "Lovelace", username: "ada#0001")
      create(:friendship, sender: user, receiver: friend, status: "accepted")

      api_get "/api/v1/friendships", user: user

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.keys).to match_array(%w[accepted sent received declined])
      expect(body["sent"]).to eq([])
      expect(body["received"]).to eq([])
      expect(body["declined"]).to eq([])
      expect(body["accepted"].length).to eq(1)

      row = body["accepted"].first
      expect(row).to include("id", "sender_id", "receiver_id", "status" => "accepted")
      expect(row["sender"]).to include(
        "id" => user.id,
        "first_name" => user.first_name,
        "last_name" => user.last_name,
        "username" => user.username
      )
      expect(row["receiver"]).to include(
        "id" => friend.id,
        "first_name" => "Ada",
        "last_name" => "Lovelace",
        "username" => "ada#0001"
      )
      expect(row["sender"]).not_to include("email", "role")
      expect(row["receiver"]).not_to include("email", "role")
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
      body = JSON.parse(response.body)
      expect(body["status"]).to eq("pending")
      expect(body["sender_id"]).to eq(user.id)
      expect(body["receiver_id"]).to eq(other.id)
      expect(body["sender"]).to include("id" => user.id)
      expect(body["receiver"]).to include("id" => other.id)
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
      expect(JSON.parse(response.body)["status"]).to eq("accepted")
    end
  end

  describe "GET /api/v1/friendships/search" do
    it "searches users without friendship" do
      user = create(:user)
      other = create(:user, first_name: "Zinedine", last_name: "Zidane", username: "zizou#0001")

      api_get "/api/v1/friendships/search", user: user,
              params: { q: { first_name_or_last_name_or_username_cont: "Zinedine" } }

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
