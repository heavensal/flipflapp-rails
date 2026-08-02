# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1 EventTeams", type: :request do
  def team_slot(event, slot)
    event.event_teams.find_by!(slot: slot)
  end

  describe "GET /api/v1/events/:event_id/event_teams" do
    it "lists teams in TEAM_SLOTS order with countable flags" do
      user = create(:user)
      event = create(:event, user: user)

      api_get "/api/v1/events/#{event.id}/event_teams", user: user

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.map { |t| t["slot"] }).to eq(%w[team_one team_two bench])
      expect(body.map { |t| t["countable"] }).to eq([ true, true, false ])
      expect(body.first.keys).to include("id", "event_id", "label", "created_at", "updated_at")
    end

    it "returns 401 without a JWT" do
      event = create(:event)
      get "/api/v1/events/#{event.id}/event_teams", as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 404 when the event is not viewable" do
      event = create(:event, is_private: true)
      stranger = create(:user)
      api_get "/api/v1/events/#{event.id}/event_teams", user: stranger
      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)).to eq("error" => { "message" => "Not found" })
    end
  end

  describe "GET /api/v1/events/:event_id/event_teams/:id" do
    it "shows one event_team with full JSON keys" do
      user = create(:user)
      event = create(:event, user: user)
      team = team_slot(event, "team_one")
      api_get "/api/v1/events/#{event.id}/event_teams/#{team.id}", user: user
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body).to include("id" => team.id, "event_id" => event.id, "slot" => "team_one", "countable" => true)
      expect(body).to include("label", "created_at", "updated_at")
    end

    it "returns 404 for a missing team id on the event" do
      user = create(:user)
      event = create(:event, user: user)
      api_get "/api/v1/events/#{event.id}/event_teams/0", user: user
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /api/v1/events/:event_id/event_teams/:id" do
    it "renames a countable event_team label" do
      user = create(:user)
      event = create(:event, user: user)
      team = team_slot(event, "team_one")

      api_patch "/api/v1/events/#{event.id}/event_teams/#{team.id}", user: user, params: {
        event_team: { label: "Les Bleus" }
      }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["label"]).to eq("Les Bleus")
      expect(team.reload.label).to eq("Les Bleus")
    end

    it "forbids non-participants on a viewable public event" do
      event = create(:event, is_private: false)
      stranger = create(:user)
      team = team_slot(event, "team_one")

      api_patch "/api/v1/events/#{event.id}/event_teams/#{team.id}", user: stranger, params: {
        event_team: { label: "Hijack" }
      }

      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body)).to eq(
        "error" => { "message" => I18n.t("event_team.flash.authorization.participant_required") }
      )
    end

    it "forbids renaming the bench with a distinct message" do
      user = create(:user)
      event = create(:event, user: user)
      bench = team_slot(event, "bench")

      api_patch "/api/v1/events/#{event.id}/event_teams/#{bench.id}", user: user, params: {
        event_team: { label: "Reserve" }
      }

      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body)).to eq(
        "error" => { "message" => I18n.t("event_team.flash.authorization.bench_not_renamable") }
      )
    end

    it "returns 422 for an invalid label" do
      user = create(:user)
      event = create(:event, user: user)
      team = team_slot(event, "team_one")

      api_patch "/api/v1/events/#{event.id}/event_teams/#{team.id}", user: user, params: {
        event_team: { label: "Real-Madrid!" }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["error"]["message"]).to eq("Validation failed")
      expect(body["error"]["details"]["label"]).to be_present
    end

    it "returns 422 for a duplicate label (case-insensitive)" do
      user = create(:user)
      event = create(:event, user: user)
      team_one = team_slot(event, "team_one")
      team_two = team_slot(event, "team_two")

      api_patch "/api/v1/events/#{event.id}/event_teams/#{team_two.id}", user: user, params: {
        event_team: { label: team_one.label.swapcase }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body).dig("error", "details", "label")).to be_present
    end

    it "returns 404 when the event is not viewable" do
      event = create(:event, is_private: true)
      stranger = create(:user)
      team = team_slot(event, "team_one")

      api_patch "/api/v1/events/#{event.id}/event_teams/#{team.id}", user: stranger, params: {
        event_team: { label: "Nope" }
      }

      expect(response).to have_http_status(:not_found)
    end
  end
end
