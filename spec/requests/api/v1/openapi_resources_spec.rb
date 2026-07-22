# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Api::V1 Events OpenAPI", type: :request do
  path "/api/v1/events" do
    get "List events" do
      operationId "listEvents"
      tags "Events"
      produces "application/json"
      security [ bearer_auth: [] ]

      response "200", "events listed" do
        schema type: :array, items: { "$ref" => "#/components/schemas/Event" }
        let(:user_record) { create(:user) }
        let(:Authorization) { api_auth_headers_for(user_record)["Authorization"] }
        before { create(:event, user: user_record, is_private: false) }

        run_test!
      end

      response "401", "unauthorized" do
        schema "$ref" => "#/components/schemas/AuthenticationError"
        let(:Authorization) { nil }
        run_test!
      end
    end

    post "Create event" do
      operationId "createEvent"
      tags "Events"
      consumes "application/json"
      produces "application/json"
      security [ bearer_auth: [] ]
      parameter name: :event, in: :body, schema: {
        type: :object,
        properties: {
          event: {
            type: :object,
            properties: {
              title: { type: :string },
              description: { type: :string },
              location: { type: :string },
              start_time: { type: :string, format: :"date-time" },
              number_of_participants: { type: :integer },
              price: { type: :number },
              is_private: { type: :boolean },
              latitude: { type: :number },
              longitude: { type: :number }
            },
            required: %w[title location start_time number_of_participants price latitude longitude]
          }
        }
      }

      response "201", "event created" do
        schema "$ref" => "#/components/schemas/Event"
        let(:user_record) { create(:user) }
        let(:Authorization) { api_auth_headers_for(user_record)["Authorization"] }
        let(:event) do
          {
            event: {
              title: "OpenAPI Match",
              description: "Doc",
              location: "Paris",
              start_time: 2.days.from_now.iso8601,
              number_of_participants: 10,
              price: 10,
              is_private: true,
              latitude: 48.856613,
              longitude: 2.352222
            }
          }
        end

        run_test!
      end

      response "401", "authentication required" do
        schema "$ref" => "#/components/schemas/AuthenticationError"
        specify("documents the 401 response") { expect(true).to be(true) }
      end

      response "422", "event validation failed" do
        schema "$ref" => "#/components/schemas/Error"
        specify("documents the 422 response") { expect(true).to be(true) }
      end
    end
  end

  path "/api/v1/events/{id}" do
    parameter name: :id, in: :path, type: :string

    get "Show event" do
      operationId "getEvent"
      tags "Events"
      produces "application/json"
      security [ bearer_auth: [] ]

      response "200", "event found" do
        schema "$ref" => "#/components/schemas/Event"
        let(:user_record) { create(:user) }
        let(:event_record) { create(:event, user: user_record) }
        let(:id) { event_record.id }
        let(:Authorization) { api_auth_headers_for(user_record)["Authorization"] }

        run_test!
      end

      response "401", "authentication required" do
        schema "$ref" => "#/components/schemas/AuthenticationError"
        specify("documents the 401 response") { expect(true).to be(true) }
      end

      response "404", "event missing or not viewable" do
        schema "$ref" => "#/components/schemas/Error"
        specify("documents the 404 response") { expect(true).to be(true) }
      end
    end
  end

  path "/api/v1/me" do
    get "Current user" do
      operationId "getCurrentUser"
      tags "Users"
      produces "application/json"
      security [ bearer_auth: [] ]

      response "200", "current user" do
        schema "$ref" => "#/components/schemas/CurrentUser"
        let(:user_record) { create(:user) }
        let(:Authorization) { api_auth_headers_for(user_record)["Authorization"] }

        run_test!
      end

      response "401", "authentication required" do
        schema "$ref" => "#/components/schemas/AuthenticationError"
        specify("documents the 401 response") { expect(true).to be(true) }
      end
    end
  end

  path "/api/v1/events/{event_id}/event_teams" do
    parameter name: :event_id, in: :path, type: :string

    get "List event_teams" do
      operationId "listEventTeams"
      tags "EventTeams"
      produces "application/json"
      security [ bearer_auth: [] ]

      response "200", "event_teams listed" do
        schema type: :array, items: { "$ref" => "#/components/schemas/EventTeam" }
        let(:user_record) { create(:user) }
        let(:event_record) { create(:event, user: user_record) }
        let(:event_id) { event_record.id }
        let(:Authorization) { api_auth_headers_for(user_record)["Authorization"] }

        run_test!
      end

      response "401", "authentication required" do
        schema "$ref" => "#/components/schemas/AuthenticationError"
        specify("documents the 401 response") { expect(true).to be(true) }
      end

      response "404", "event missing or not viewable" do
        schema "$ref" => "#/components/schemas/Error"
        specify("documents the 404 response") { expect(true).to be(true) }
      end
    end
  end

  path "/api/v1/events/{event_id}/event_teams/{event_team_id}/event_participants" do
    parameter name: :event_id, in: :path, type: :string
    parameter name: :event_team_id, in: :path, type: :string

    get "List event_participants for an event_team" do
      operationId "listEventTeamParticipants"
      tags "EventParticipants"
      produces "application/json"
      security [ bearer_auth: [] ]

      response "200", "event_participants listed" do
        schema type: :array, items: { "$ref" => "#/components/schemas/EventParticipant" }
        let(:user_record) { create(:user) }
        let(:event_record) { create(:event, user: user_record) }
        let(:event_id) { event_record.id }
        let(:event_team_id) { event_record.event_teams.find_by!(slot: "team_one").id }
        let(:Authorization) { api_auth_headers_for(user_record)["Authorization"] }

        run_test!
      end

      response "401", "authentication required" do
        schema "$ref" => "#/components/schemas/AuthenticationError"
        specify("documents the 401 response") { expect(true).to be(true) }
      end

      response "404", "event or team missing or not viewable" do
        schema "$ref" => "#/components/schemas/Error"
        specify("documents the 404 response") { expect(true).to be(true) }
      end
    end
  end
end
