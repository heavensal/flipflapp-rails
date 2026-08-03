# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1 nested EventTeam participants", type: :request do
  describe "GET /api/v1/events/:event_id/event_teams/:event_team_id/event_participants" do
    it "lists participants for one event_team" do
      user = create(:user)
      event = create(:event, user: user)
      team_one = event.event_teams.find_by!(slot: "team_one")

      api_get "/api/v1/events/#{event.id}/event_teams/#{team_one.id}/event_participants", user: user

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.length).to eq(1)
      expect(body.first["user_id"]).to eq(user.id)
      expect(body.first["event_team_id"]).to eq(team_one.id)
    end

    it "returns an empty array for a valid team with no participants" do
      organizer = create(:user)
      event = create(:event, user: organizer)
      team_two = event.event_teams.find_by!(slot: "team_two")

      api_get "/api/v1/events/#{event.id}/event_teams/#{team_two.id}/event_participants", user: organizer

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([])
    end

    it "returns 404 when event_team_id is not on the event" do
      user = create(:user)
      event = create(:event, user: user)

      api_get "/api/v1/events/#{event.id}/event_teams/0/event_participants", user: user

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)).to eq("error" => { "message" => "Not found" })
    end

    it "returns 404 when the event is not viewable" do
      event = create(:event, is_private: true)
      stranger = create(:user)
      team = event.event_teams.find_by!(slot: "team_one")

      api_get "/api/v1/events/#{event.id}/event_teams/#{team.id}/event_participants", user: stranger

      expect(response).to have_http_status(:not_found)
    end

    it "returns 401 without a JWT" do
      event = create(:event)
      team = event.event_teams.find_by!(slot: "team_one")
      get "/api/v1/events/#{event.id}/event_teams/#{team.id}/event_participants", as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
