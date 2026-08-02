# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Api::V1 Events OpenAPI CRUD", type: :request do
  include OpenapiContractHelpers
  error = { "$ref" => "#/components/schemas/Error" }
  auth_error = { "$ref" => "#/components/schemas/Error" }
  event = { "$ref" => "#/components/schemas/Event" }

  path "/api/v1/events" do
    get "List visible upcoming events" do
      operationId "listEvents"
      tags "Events"
      description "Returns events visible to the current user with start_time in the future. " \
                  "Excludes past events and private events the viewer cannot see. " \
                  "Each Event includes current_user viewer flags."
      produces "application/json"
      security [ bearer_auth: [] ]

      response "200", "upcoming visible events" do
        schema type: :array, items: event
        example "application/json", :list, [ OpenapiEventsExamples.event_example(viewer_context: :author) ]
        let(:user_record) { create(:user) }
        let(:Authorization) { api_auth_headers_for(user_record)["Authorization"] }
        before { create(:event, user: user_record, is_private: false) }
        run_test!
      end

      response "401", "authentication required" do
        schema auth_error
        example "application/json", :unauthorized, OpenapiEventsExamples::AUTH_ERROR_401
        let(:Authorization) { nil }
        run_test!
      end
    end

    post "Create an event" do
      operationId "createEvent"
      tags "Events"
      description "Creates a match. Side effects: three event_teams (team_one, team_two, bench), " \
                  "author auto-joined on team_one, bench reminder scheduled. " \
                  "Send price/latitude/longitude as numbers; responses serialize them as strings."
      consumes "application/json"
      produces "application/json"
      security [ bearer_auth: [] ]
      parameter name: :event_body, in: :body, required: true, schema: {
        type: :object,
        required: [ :event ],
        properties: { event: { "$ref" => "#/components/schemas/EventCreateInput" } }
      }
      request_body_example value: OpenapiEventsExamples::CREATE_EVENT_REQUEST, name: "create", summary: "Create match"

      response "201", "event created" do
        schema event
        example "application/json", :created, OpenapiEventsExamples.event_example(viewer_context: :author)
        let(:user_record) { create(:user) }
        let(:Authorization) { api_auth_headers_for(user_record)["Authorization"] }
        let(:event_body) { OpenapiEventsExamples::CREATE_EVENT_REQUEST.deep_dup.tap { |b|
          b[:event][:start_time] = 2.days.from_now.iso8601
        } }
        run_test!
      end

      documented_response "401", "authentication required",
                          examples: [ { name: :unauthorized, value: OpenapiEventsExamples::AUTH_ERROR_401 } ] do
        schema auth_error
      end
      documented_response "422", "validation failed",
                          examples: [ { name: :validation, value: OpenapiEventsExamples::ERROR_422_VALIDATION } ] do
        schema error
      end
    end
  end

  path "/api/v1/events/{id}" do
    parameter name: :id, in: :path, required: true, schema: { type: :integer, format: :int64 }

    get "Show an event" do
      operationId "getEvent"
      tags "Events"
      description "Loads one event plus current_user flags for CTAs. " \
                  "Private or non-viewable events return 404 (not 403) — never distinguish missing vs hidden."
      produces "application/json"
      security [ bearer_auth: [] ]

      response "200", "event found" do
        schema event
        example "application/json", :author, OpenapiEventsExamples.event_example(viewer_context: :author)
        example "application/json", :participant, OpenapiEventsExamples.event_example(viewer_context: :participant)
        example "application/json", :invited, OpenapiEventsExamples.event_example(viewer_context: :invited)
        example "application/json", :public_stranger, OpenapiEventsExamples.event_example(viewer_context: :stranger)
        let(:user_record) { create(:user) }
        let(:event_record) { create(:event, user: user_record) }
        let(:id) { event_record.id }
        let(:Authorization) { api_auth_headers_for(user_record)["Authorization"] }
        run_test!
      end

      documented_response "401", "authentication required",
                          examples: [ { name: :unauthorized, value: OpenapiEventsExamples::AUTH_ERROR_401 } ] do
        schema auth_error
      end
      documented_response "404", "missing or not viewable",
                          examples: [ { name: :not_found, value: OpenapiEventsExamples::ERROR_404 } ] do
        schema error
      end
    end

    patch "Update an event" do
      operationId "updateEvent"
      tags "Events"
      description "Author-only edit. Viewable non-author → 403; not viewable → 404. " \
                  "Tracked field changes may notify other participants (updated)."
      consumes "application/json"
      produces "application/json"
      security [ bearer_auth: [] ]
      parameter name: :event_update, in: :body, required: true, schema: {
        type: :object,
        required: [ :event ],
        properties: { event: { "$ref" => "#/components/schemas/EventInput" } }
      }
      request_body_example value: OpenapiEventsExamples::UPDATE_EVENT_REQUEST, name: "update", summary: "Patch fields"

      documented_response "200", "event updated",
                          examples: [ { name: :updated, value: OpenapiEventsExamples.event_example(viewer_context: :author) } ] do
        schema event
      end
      documented_response "401", "authentication required",
                          examples: [ { name: :unauthorized, value: OpenapiEventsExamples::AUTH_ERROR_401 } ] do
        schema auth_error
      end
      documented_response "403", "not the author",
                          examples: [ { name: :forbidden, value: OpenapiEventsExamples::ERROR_403 } ] do
        schema error
      end
      documented_response "404", "missing or not viewable",
                          examples: [ { name: :not_found, value: OpenapiEventsExamples::ERROR_404 } ] do
        schema error
      end
      documented_response "422", "validation failed",
                          examples: [ { name: :validation, value: OpenapiEventsExamples::ERROR_422_VALIDATION } ] do
        schema error
      end
    end

    delete "Delete an event" do
      operationId "deleteEvent"
      tags "Events"
      description "Author cancels the match (204 empty body). Notifies other participants (canceled); " \
                  "cascades teams, participants, and invitations."
      produces "application/json"
      security [ bearer_auth: [] ]

      documented_response "204", "event deleted"
      documented_response "401", "authentication required",
                          examples: [ { name: :unauthorized, value: OpenapiEventsExamples::AUTH_ERROR_401 } ] do
        schema auth_error
      end
      documented_response "403", "not the author",
                          examples: [ { name: :forbidden, value: OpenapiEventsExamples::ERROR_403 } ] do
        schema error
      end
      documented_response "404", "missing or not viewable",
                          examples: [ { name: :not_found, value: OpenapiEventsExamples::ERROR_404 } ] do
        schema error
      end
    end
  end
end
