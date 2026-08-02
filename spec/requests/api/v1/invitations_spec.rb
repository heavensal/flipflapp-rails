# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1 Invitations", type: :request do
  describe "POST /api/v1/events/:event_id/invitations" do
    it "invites accepted friends" do
      organizer = create(:user)
      event = create(:event, user: organizer)
      friend = create(:user)
      create(:friendship, sender: organizer, receiver: friend, status: "accepted")

      expect {
        api_post "/api/v1/events/#{event.id}/invitations", user: organizer, params: {
          user_ids: [ friend.id ]
        }
      }.to change(Invitation, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body).first["user_id"]).to eq(friend.id)
    end

    it "forbids non-participants" do
      organizer = create(:user)
      event = create(:event, user: organizer, is_private: false)
      stranger = create(:user)
      friend = create(:user)
      create(:friendship, sender: stranger, receiver: friend, status: "accepted")

      api_post "/api/v1/events/#{event.id}/invitations", user: stranger, params: {
        user_ids: [ friend.id ]
      }

      expect(response).to have_http_status(:forbidden)
    end

    it "returns 422 when no eligible users remain" do
      organizer = create(:user)
      event = create(:event, user: organizer)

      api_post "/api/v1/events/#{event.id}/invitations", user: organizer, params: {
        user_ids: []
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to eq("error" => { "message" => "No users to invite" })
    end
  end

  describe "GET /api/v1/events/:event_id/invitations" do
    it "lists pending invitations" do
      organizer = create(:user)
      event = create(:event, user: organizer)
      friend = create(:user)
      create(:friendship, sender: organizer, receiver: friend, status: "accepted")
      create(:invitation, event: event, user: friend)

      api_get "/api/v1/events/#{event.id}/invitations", user: organizer

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).map { |i| i["user_id"] }).to include(friend.id)
    end
  end
end
