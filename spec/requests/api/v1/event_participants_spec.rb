# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1 EventParticipants writes", type: :request do
  describe "POST /api/v1/events/:event_id/event_participants" do
    it "joins with 201 then switches team with 200" do
      organizer = create(:user)
      event = create(:event, user: organizer, is_private: false)
      friend = create(:user)
      team_two = event.event_teams.find_by!(slot: "team_two")
      bench = event.event_teams.find_by!(slot: "bench")

      api_post "/api/v1/events/#{event.id}/event_participants", user: friend, params: {
        event_participant: { event_team_id: bench.id }
      }
      expect(response).to have_http_status(:created)

      api_post "/api/v1/events/#{event.id}/event_participants", user: friend, params: {
        event_participant: { event_team_id: team_two.id }
      }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["event_team_id"]).to eq(team_two.id)
    end

    it "returns 404 when the event is not joinable" do
      event = create(:event, is_private: true)
      stranger = create(:user)
      team = event.event_teams.find_by!(slot: "bench")

      api_post "/api/v1/events/#{event.id}/event_participants", user: stranger, params: {
        event_participant: { event_team_id: team.id }
      }

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for an event_team_id that does not belong to the event" do
      organizer = create(:user)
      event = create(:event, user: organizer, is_private: false)
      other = create(:event, is_private: false)
      foreign_team = other.event_teams.find_by!(slot: "bench")
      joiner = create(:user)

      api_post "/api/v1/events/#{event.id}/event_participants", user: joiner, params: {
        event_participant: { event_team_id: foreign_team.id }
      }

      expect(response).to have_http_status(:not_found)
    end

    it "returns 422 when the chosen countable team is full" do
      organizer = create(:user)
      event = create(:event, user: organizer, is_private: false, number_of_participants: 2)
      team_one = event.event_teams.find_by!(slot: "team_one")
      joiner = create(:user)

      api_post "/api/v1/events/#{event.id}/event_participants", user: joiner, params: {
        event_participant: { event_team_id: team_one.id }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body.dig("error", "message")).to eq("Validation failed")
      expect(body.dig("error", "details")).to have_key("event_team")
    end
  end

  describe "DELETE /api/v1/event_participants/:id" do
    it "allows a user to leave" do
      organizer = create(:user)
      event = create(:event, user: organizer, is_private: false)
      friend = create(:user)
      team_two = event.event_teams.find_by!(slot: "team_two")
      participation = create(:event_participant, event: event, user: friend, event_team: team_two)

      expect {
        api_delete "/api/v1/event_participants/#{participation.id}", user: friend
      }.to change(EventParticipant, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
