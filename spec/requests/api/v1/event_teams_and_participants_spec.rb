# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1 EventTeams and EventParticipants", type: :request do
  describe "GET /api/v1/events/:event_id/event_teams" do
    it "lists the three event_teams" do
      user = create(:user)
      event = create(:event, user: user)

      api_get "/api/v1/events/#{event.id}/event_teams", user: user

      expect(response).to have_http_status(:ok)
      slots = JSON.parse(response.body).map { |t| t["slot"] }
      expect(slots).to match_array(%w[team_one team_two bench])
    end
  end

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
  end

  describe "POST /api/v1/events/:event_id/event_participants" do
    it "joins an event_team" do
      organizer = create(:user)
      event = create(:event, user: organizer, is_private: false)
      friend = create(:user)
      create(:friendship, sender: organizer, receiver: friend, status: "accepted")
      bench = event.event_teams.find_by!(slot: "bench")

      expect {
        api_post "/api/v1/events/#{event.id}/event_participants", user: friend, params: {
          event_participant: { event_team_id: bench.id }
        }
      }.to change(EventParticipant, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["event_team_id"]).to eq(bench.id)
    end
  end

  describe "PATCH /api/v1/events/:event_id/event_teams/:id" do
    it "renames a countable event_team label" do
      user = create(:user)
      event = create(:event, user: user)
      team_one = event.event_teams.find_by!(slot: "team_one")

      api_patch "/api/v1/events/#{event.id}/event_teams/#{team_one.id}", user: user, params: {
        event_team: { label: "Les Bleus" }
      }

      expect(response).to have_http_status(:ok)
      expect(team_one.reload.label).to eq("Les Bleus")
    end
  end

  describe "DELETE /api/v1/event_participants/:id" do
    it "allows a user to leave" do
      organizer = create(:user)
      event = create(:event, user: organizer, is_private: false)
      friend = create(:user)
      create(:friendship, sender: organizer, receiver: friend, status: "accepted")
      team_two = event.event_teams.find_by!(slot: "team_two")
      participation = create(:event_participant, event: event, user: friend, event_team: team_two)

      expect {
        api_delete "/api/v1/event_participants/#{participation.id}", user: friend
      }.to change(EventParticipant, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
