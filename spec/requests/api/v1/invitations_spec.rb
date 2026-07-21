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
