# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Api::V1 Events OpenAPI nested", type: :request do
  include OpenapiContractHelpers
  error = { "$ref" => "#/components/schemas/Error" }
  auth_error = { "$ref" => "#/components/schemas/Error" }
  team = { "$ref" => "#/components/schemas/EventTeam" }
  participant = { "$ref" => "#/components/schemas/EventParticipant" }
  invitation = { "$ref" => "#/components/schemas/Invitation" }

  path "/api/v1/events/{event_id}/event_teams" do
    parameter name: :event_id, in: :path, required: true, schema: { type: :integer, format: :int64 }

    get "List event teams" do
      operationId "listEventTeams"
      tags "EventTeams"
      description "Load the three squad slots for team UI (labels + countable). " \
                  "Order is always team_one, team_two, bench (Event::TEAM_SLOTS). " \
                  "Show label in UI; keep slot for logic. Disable rename when countable is false. " \
                  "No POST /event_teams — teams are created with the Event. Next: listEventTeamParticipants " \
                  "per team, or getEventTeam → updateEventTeam when the viewer is a participant."
      produces "application/json"
      security [ bearer_auth: [] ]

      response "200", "event teams listed in domain slot order" do
        schema type: :array, items: team
        example "application/json", :teams, [
          OpenapiEventsExamples::EVENT_TEAM_ONE,
          OpenapiEventsExamples::EVENT_TEAM_TWO,
          OpenapiEventsExamples::EVENT_TEAM_BENCH
        ]
        let(:user_record) { create(:user) }
        let(:event_record) { create(:event, user: user_record) }
        let(:event_id) { event_record.id }
        let(:Authorization) { api_auth_headers_for(user_record)["Authorization"] }
        run_test! do |response|
          slots = JSON.parse(response.body).map { |row| row["slot"] }
          expect(slots).to eq(%w[team_one team_two bench])
        end
      end

      documented_response "401", "authentication required",
                          examples: [ { name: :unauthorized, value: OpenapiEventsExamples::AUTH_ERROR_401 } ] do
        schema auth_error
      end
      documented_response "404", "event missing or not viewable",
                          examples: [ { name: :not_found, value: OpenapiEventsExamples::ERROR_404 } ] do
        schema error
      end
    end
  end

  path "/api/v1/events/{event_id}/event_teams/{id}" do
    parameter name: :event_id, in: :path, required: true, schema: { type: :integer, format: :int64 }
    parameter name: :id, in: :path, required: true, schema: { type: :integer, format: :int64 }

    get "Show an event team" do
      operationId "getEventTeam"
      tags "EventTeams"
      description "Single team for rename sheet / team detail. " \
                  "404 if event/team missing or event not viewable (same opacity as Events). " \
                  "Next: updateEventTeam when countable and viewer is a participant; else listEventTeamParticipants."
      produces "application/json"
      security [ bearer_auth: [] ]

      documented_response "200", "event team found",
                          examples: [ { name: :team, value: OpenapiEventsExamples::EVENT_TEAM_ONE } ] do
        schema team
      end
      documented_response "401", "authentication required",
                          examples: [ { name: :unauthorized, value: OpenapiEventsExamples::AUTH_ERROR_401 } ] do
        schema auth_error
      end
      documented_response "404", "event or team missing or not viewable",
                          examples: [ { name: :not_found, value: OpenapiEventsExamples::ERROR_404 } ] do
        schema error
      end
    end

    patch "Rename a countable event team" do
      operationId "updateEventTeam"
      tags "EventTeams"
      description "Rename display label only on a countable team (team_one / team_two). " \
                  "Must be a participant (in_this_event?). Bench → 403. Viewable public stranger → 403 (not 404). " \
                  "Body permits label only — slot is immutable and ignored if sent. " \
                  "Side effects: none (no capacity change, no notifications). " \
                  "Next: apply response locally or refetch getEventTeam / listEventTeams; do not refetch participants. " \
                  "No DELETE /event_teams."
      consumes "application/json"
      produces "application/json"
      security [ bearer_auth: [] ]
      parameter name: :event_team_update, in: :body, required: true, schema: {
        type: :object,
        required: [ :event_team ],
        properties: {
          event_team: {
            type: :object,
            required: [ :label ],
            properties: {
              label: {
                type: :string,
                maxLength: 24,
                description: "Letters, digits, spaces only. Trimmed and collapsed server-side."
              }
            }
          }
        }
      }
      request_body_example value: OpenapiEventsExamples::RENAME_TEAM_REQUEST, name: "rename", summary: "Rename label"

      documented_response "200", "event team renamed",
                          examples: [ {
                            name: :renamed,
                            value: OpenapiEventsExamples::EVENT_TEAM_ONE.merge(label: "France 98")
                          } ] do
        schema team
      end
      documented_response "401", "authentication required",
                          examples: [ { name: :unauthorized, value: OpenapiEventsExamples::AUTH_ERROR_401 } ] do
        schema auth_error
      end
      documented_response "403", "not a participant or team is bench",
                          examples: [
                            { name: :not_participant, value: OpenapiEventsExamples::ERROR_403_RENAME_NOT_PARTICIPANT },
                            { name: :bench, value: OpenapiEventsExamples::ERROR_403_RENAME_BENCH }
                          ] do
        schema error
      end
      documented_response "404", "event or team missing or not viewable",
                          examples: [ { name: :not_found, value: OpenapiEventsExamples::ERROR_404 } ] do
        schema error
      end
      documented_response "422", "label validation failed",
                          examples: [
                            { name: :invalid_characters, value: OpenapiEventsExamples::ERROR_422_TEAM_LABEL },
                            { name: :taken, value: OpenapiEventsExamples::ERROR_422_TEAM_LABEL_TAKEN },
                            { name: :too_long, value: OpenapiEventsExamples::ERROR_422_TEAM_LABEL_TOO_LONG }
                          ] do
        schema error
      end
    end
  end

  path "/api/v1/events/{event_id}/event_participants" do
    parameter name: :event_id, in: :path, required: true, schema: { type: :integer, format: :int64 }

    get "List all event participants" do
      operationId "listEventParticipants"
      tags "EventParticipants"
      description "Full roster for the event (all teams). Use when composing the invite picker."
      produces "application/json"
      security [ bearer_auth: [] ]

      documented_response "200", "participants listed",
                          examples: [ { name: :roster, value: [ OpenapiEventsExamples::EVENT_PARTICIPANT ] } ] do
        schema type: :array, items: participant
      end
      documented_response "401", "authentication required",
                          examples: [ { name: :unauthorized, value: OpenapiEventsExamples::AUTH_ERROR_401 } ] do
        schema auth_error
      end
      documented_response "404", "event missing or not viewable",
                          examples: [ { name: :not_found, value: OpenapiEventsExamples::ERROR_404 } ] do
        schema error
      end
    end

    post "Join an event or switch team" do
      operationId "joinOrSwitchEventParticipant"
      tags "EventParticipants"
      description "First join → 201; already a participant switching team → 200. " \
                  "Not joinable or foreign event_team_id → 404 (opaque). Team/countable full → 422 with details. " \
                  "After success, refetch listEventTeamParticipants for the target team."
      consumes "application/json"
      produces "application/json"
      security [ bearer_auth: [] ]
      parameter name: :participation, in: :body, required: true, schema: {
        type: :object,
        required: [ :event_participant ],
        properties: {
          event_participant: {
            type: :object,
            required: [ :event_team_id ],
            properties: { event_team_id: { type: :integer, format: :int64 } }
          }
        }
      }
      request_body_example value: OpenapiEventsExamples::JOIN_REQUEST, name: "join", summary: "Join or switch"

      documented_response "200", "switched team",
                          examples: [ { name: :switched, value: OpenapiEventsExamples::EVENT_PARTICIPANT } ] do
        schema participant
      end
      documented_response "201", "joined",
                          examples: [ { name: :joined, value: OpenapiEventsExamples::EVENT_PARTICIPANT } ] do
        schema participant
      end
      documented_response "401", "authentication required",
                          examples: [ { name: :unauthorized, value: OpenapiEventsExamples::AUTH_ERROR_401 } ] do
        schema auth_error
      end
      documented_response "404", "not joinable or team not on event",
                          examples: [ { name: :not_found, value: OpenapiEventsExamples::ERROR_404 } ] do
        schema error
      end
      documented_response "422", "team or countable full",
                          examples: [ { name: :full, value: OpenapiEventsExamples::ERROR_422_TEAM_FULL } ] do
        schema error
      end
    end
  end

  path "/api/v1/events/{event_id}/event_teams/{event_team_id}/event_participants" do
    parameter name: :event_id, in: :path, required: true, schema: { type: :integer, format: :int64 }
    parameter name: :event_team_id, in: :path, required: true, schema: { type: :integer, format: :int64 }

    get "List participants for one event team" do
      operationId "listEventTeamParticipants"
      tags "EventParticipants"
      description "Roster for one event_team (iOS granular refetch after joinOrSwitchEventParticipant). " \
                  "Valid empty team → 200 []. Unknown event_team_id on the event → 404 (not empty array). " \
                  "Event missing or not viewable → 404."
      produces "application/json"
      security [ bearer_auth: [] ]

      response "200", "team participants listed" do
        schema type: :array, items: participant
        example "application/json", :team_roster, [ OpenapiEventsExamples::EVENT_PARTICIPANT ]
        let(:user_record) { create(:user) }
        let(:event_record) { create(:event, user: user_record) }
        let(:event_id) { event_record.id }
        let(:event_team_id) { event_record.event_teams.find_by!(slot: "team_one").id }
        let(:Authorization) { api_auth_headers_for(user_record)["Authorization"] }
        run_test!
      end

      documented_response "401", "authentication required",
                          examples: [ { name: :unauthorized, value: OpenapiEventsExamples::AUTH_ERROR_401 } ] do
        schema auth_error
      end
      documented_response "404", "event or team missing or not viewable",
                          examples: [ { name: :not_found, value: OpenapiEventsExamples::ERROR_404 } ] do
        schema error
      end
    end
  end

  path "/api/v1/event_participants/{id}" do
    parameter name: :id, in: :path, required: true, schema: { type: :integer, format: :int64 }

    delete "Leave an event" do
      operationId "deleteEventParticipant"
      tags "EventParticipants"
      description "Current user deletes own participation only (204 empty). Other user's id → 404. " \
                  "Leaving a countable team may notify remaining players (left)."
      produces "application/json"
      security [ bearer_auth: [] ]

      documented_response "204", "participation deleted"
      documented_response "401", "authentication required",
                          examples: [ { name: :unauthorized, value: OpenapiEventsExamples::AUTH_ERROR_401 } ] do
        schema auth_error
      end
      documented_response "404", "participation not found for current user",
                          examples: [ { name: :not_found, value: OpenapiEventsExamples::ERROR_404 } ] do
        schema error
      end
    end
  end

  path "/api/v1/events/{event_id}/invitations" do
    parameter name: :event_id, in: :path, required: true, schema: { type: :integer, format: :int64 }

    get "List event invitations" do
      operationId "listEventInvitations"
      tags "Invitations"
      description "Pending invitations for the event. Any viewer of the event may list them."
      produces "application/json"
      security [ bearer_auth: [] ]

      documented_response "200", "invitations listed",
                          examples: [ { name: :invites, value: [ OpenapiEventsExamples::INVITATION ] } ] do
        schema type: :array, items: invitation
      end
      documented_response "401", "authentication required",
                          examples: [ { name: :unauthorized, value: OpenapiEventsExamples::AUTH_ERROR_401 } ] do
        schema auth_error
      end
      documented_response "404", "event missing or not viewable",
                          examples: [ { name: :not_found, value: OpenapiEventsExamples::ERROR_404 } ] do
        schema error
      end
    end

    post "Invite accepted friends to an event" do
      operationId "createEventInvitations"
      tags "Invitations"
      description "Participant invites eligible accepted friends (not already in or invited). " \
                  "Compose picker: listFriendships accepted − listEventParticipants − listEventInvitations. " \
                  "Empty or ineligible selection → 422 No users to invite. Creates invited notifications."
      consumes "application/json"
      produces "application/json"
      security [ bearer_auth: [] ]
      parameter name: :invitations, in: :body, required: true, schema: {
        type: :object,
        required: [ :user_ids ],
        properties: {
          user_ids: {
            type: :array, minItems: 1, uniqueItems: true,
            items: { type: :integer, format: :int64 }
          }
        }
      }
      request_body_example value: OpenapiEventsExamples::INVITE_REQUEST, name: "invite", summary: "Invite friends"

      documented_response "201", "friends invited",
                          examples: [ { name: :created, value: [ OpenapiEventsExamples::INVITATION ] } ] do
        schema type: :array, items: invitation
      end
      documented_response "401", "authentication required",
                          examples: [ { name: :unauthorized, value: OpenapiEventsExamples::AUTH_ERROR_401 } ] do
        schema auth_error
      end
      documented_response "403", "not a participant",
                          examples: [ { name: :forbidden, value: OpenapiEventsExamples::ERROR_403 } ] do
        schema error
      end
      documented_response "404", "event missing or not viewable",
                          examples: [ { name: :not_found, value: OpenapiEventsExamples::ERROR_404 } ] do
        schema error
      end
      documented_response "422", "no eligible users",
                          examples: [ { name: :none, value: OpenapiEventsExamples::ERROR_422_NO_USERS_TO_INVITE } ] do
        schema error
      end
    end
  end
end
