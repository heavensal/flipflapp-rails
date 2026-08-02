# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1 EventParticipants index", type: :request do
  describe "GET /api/v1/events/:event_id/event_participants" do
    it "lists all participants for the event" do
      user = create(:user)
      event = create(:event, user: user)

      api_get "/api/v1/events/#{event.id}/event_participants", user: user

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.map { |p| p["user_id"] }).to include(user.id)
      expect(body.first).to have_key("user")
    end
  end
end
