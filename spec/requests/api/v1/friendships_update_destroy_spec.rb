# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1 Friendships update/destroy", type: :request do
  describe "PATCH /api/v1/friendships/:id" do
    it "declines a pending request as receiver" do
      sender = create(:user)
      receiver = create(:user)
      friendship = create(:friendship, sender: sender, receiver: receiver, status: "pending")

      api_patch "/api/v1/friendships/#{friendship.id}", user: receiver, params: { status: "declined" }

      expect(response).to have_http_status(:ok)
      expect(friendship.reload.status).to eq("declined")
      expect(JSON.parse(response.body)["status"]).to eq("declined")
    end

    it "forbids the sender from accepting or declining" do
      sender = create(:user)
      receiver = create(:user)
      friendship = create(:friendship, sender: sender, receiver: receiver, status: "pending")

      api_patch "/api/v1/friendships/#{friendship.id}", user: sender, params: { status: "accepted" }

      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body)).to eq("error" => { "message" => "Forbidden" })
      expect(friendship.reload.status).to eq("pending")
    end

    it "forbids updates when the friendship is not pending" do
      sender = create(:user)
      receiver = create(:user)
      friendship = create(:friendship, sender: sender, receiver: receiver, status: "accepted")

      api_patch "/api/v1/friendships/#{friendship.id}", user: receiver, params: { status: "declined" }

      expect(response).to have_http_status(:forbidden)
    end

    it "returns 404 for a missing friendship" do
      user = create(:user)

      api_patch "/api/v1/friendships/0", user: user, params: { status: "accepted" }

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)).to eq("error" => { "message" => "Not found" })
    end
  end

  describe "DELETE /api/v1/friendships/:id" do
    it "allows the sender to cancel a pending request" do
      sender = create(:user)
      receiver = create(:user)
      friendship = create(:friendship, sender: sender, receiver: receiver, status: "pending")

      api_delete "/api/v1/friendships/#{friendship.id}", user: sender

      expect(response).to have_http_status(:no_content)
      expect(response.body).to be_blank
      expect(Friendship).not_to exist(friendship.id)
    end

    it "forbids the receiver from deleting a pending request" do
      sender = create(:user)
      receiver = create(:user)
      friendship = create(:friendship, sender: sender, receiver: receiver, status: "pending")

      api_delete "/api/v1/friendships/#{friendship.id}", user: receiver

      expect(response).to have_http_status(:forbidden)
      expect(Friendship).to exist(friendship.id)
    end

    it "allows either party to unfriend an accepted friendship" do
      sender = create(:user)
      receiver = create(:user)
      friendship = create(:friendship, sender: sender, receiver: receiver, status: "accepted")

      api_delete "/api/v1/friendships/#{friendship.id}", user: receiver

      expect(response).to have_http_status(:no_content)
      expect(Friendship).not_to exist(friendship.id)
    end

    it "allows the receiver to remove a declined friendship" do
      sender = create(:user)
      receiver = create(:user)
      friendship = create(:friendship, sender: sender, receiver: receiver, status: "declined")

      api_delete "/api/v1/friendships/#{friendship.id}", user: receiver

      expect(response).to have_http_status(:no_content)
      expect(Friendship).not_to exist(friendship.id)
    end

    it "forbids the sender from removing a declined friendship" do
      sender = create(:user)
      receiver = create(:user)
      friendship = create(:friendship, sender: sender, receiver: receiver, status: "declined")

      api_delete "/api/v1/friendships/#{friendship.id}", user: sender

      expect(response).to have_http_status(:forbidden)
      expect(Friendship).to exist(friendship.id)
    end

    it "returns 404 for a missing friendship" do
      user = create(:user)

      api_delete "/api/v1/friendships/0", user: user

      expect(response).to have_http_status(:not_found)
    end
  end
end
