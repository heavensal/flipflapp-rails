# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1 Friendships create/search", type: :request do
  describe "POST /api/v1/friendships" do
    it "returns 404 when the target user does not exist" do
      user = create(:user)

      api_post "/api/v1/friendships", user: user, params: { user_id: 0 }

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)).to eq("error" => { "message" => "Not found" })
    end

    it "returns 422 when friending yourself" do
      user = create(:user)

      api_post "/api/v1/friendships", user: user, params: { user_id: user.id }

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body.dig("error", "message")).to eq("Validation failed")
      expect(body.dig("error", "details")).to have_key("receiver_id")
    end

    it "returns 422 for a duplicate directed request" do
      sender = create(:user)
      receiver = create(:user)
      create(:friendship, sender: sender, receiver: receiver, status: "pending")

      api_post "/api/v1/friendships", user: sender, params: { user_id: receiver.id }

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body.dig("error", "message")).to eq("Validation failed")
      expect(body.dig("error", "details")).to be_present
    end

    it "returns 422 when a reverse friendship already exists" do
      sender = create(:user)
      receiver = create(:user)
      create(:friendship, sender: sender, receiver: receiver, status: "accepted")

      api_post "/api/v1/friendships", user: receiver, params: { user_id: sender.id }

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body.dig("error", "details")).to have_key("base")
    end

    it "enqueues a friendship_requested notification for the receiver" do
      sender = create(:user)
      receiver = create(:user)

      expect {
        api_post "/api/v1/friendships", user: sender, params: { user_id: receiver.id }
      }.to have_enqueued_job(Notifications::DeliverOneJob)

      expect(response).to have_http_status(:created)
    end
  end

  describe "GET /api/v1/friendships/search" do
    it "returns an empty array when q is missing" do
      user = create(:user)
      create(:user, first_name: "Visible")

      api_get "/api/v1/friendships/search", user: user

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([])
    end

    it "returns an empty array when q is blank" do
      user = create(:user)

      api_get "/api/v1/friendships/search", user: user, params: { q: {} }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([])
    end

    it "excludes users who already have any friendship with the current user" do
      user = create(:user)
      pending_other = create(:user, first_name: "PendingMatch")
      accepted_other = create(:user, first_name: "AcceptedMatch")
      declined_other = create(:user, first_name: "DeclinedMatch")
      free_other = create(:user, first_name: "FreeMatch")
      create(:friendship, sender: user, receiver: pending_other, status: "pending")
      create(:friendship, sender: user, receiver: accepted_other, status: "accepted")
      create(:friendship, sender: declined_other, receiver: user, status: "declined")

      api_get "/api/v1/friendships/search", user: user,
              params: { q: { first_name_or_last_name_or_username_cont: "Match" } }

      ids = JSON.parse(response.body).map { |row| row["id"] }
      expect(ids).to include(free_other.id)
      expect(ids).not_to include(pending_other.id, accepted_other.id, declined_other.id, user.id)
    end
  end
end
