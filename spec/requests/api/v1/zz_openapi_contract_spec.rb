# frozen_string_literal: true

require "swagger_helper"

# Documentation-only rswag metadata for Notifications + DeviceTokens.
# Auth/Users/Events/Friendships OpenAPI live in their executable specs.
RSpec.describe "Api::V1 complete OpenAPI contract", type: :request do
  include OpenapiContractHelpers

  error_schema = { "$ref" => "#/components/schemas/Error" }
  notification_schema = { "$ref" => "#/components/schemas/Notification" }

  notification_example = {
    id: 10,
    kind: "invited",
    read: false,
    payload: { "sender" => "Ada" },
    created_at: "2026-08-02T18:00:00.000Z",
    notifiable_type: "Event",
    notifiable_id: 3
  }

  path "/api/v1/notifications" do
    get "List recent inbox notifications" do
      operationId "listNotifications"
      tags "Notifications"
      description "Returns at most 20 recent inbox notifications (newest first). " \
                  "Excludes friendship_requested — friends-request UX is listFriendships.received. " \
                  "Push for friendship_requested may still arrive — route to friendships, not inbox. " \
                  "Full contract: docs/mobile/notifications/."
      security [ bearer_auth: [] ]
      produces "application/json"
      documented_response "200", "notifications listed", examples: [
        { name: :example, value: [ notification_example ] }
      ] do
        schema type: :array, maxItems: 20, items: notification_schema
      end
      documented_response "401", "authentication required", examples: [
        { name: :example, value: { error: { message: "Vous devez vous connecter ou vous inscrire pour continuer." } } }
      ] do
        schema error_schema
      end
    end
  end

  path "/api/v1/notifications/{id}/read" do
    parameter name: :id, in: :path, required: true, schema: { type: :integer, format: :int64 }
    patch "Mark a notification as read" do
      operationId "readNotification"
      tags "Notifications"
      description "Marks one inbox notification read. friendship_requested ids → 404 (not in inbox scope)."
      security [ bearer_auth: [] ]
      produces "application/json"
      documented_response "200", "notification marked as read", examples: [
        { name: :example, value: notification_example.merge(read: true) }
      ] do
        schema notification_schema
      end
      documented_response "401", "authentication required" do
        schema error_schema
      end
      documented_response "404", "inbox notification not found for current user", examples: [
        { name: :example, value: { error: { message: "Not found" } } }
      ] do
        schema error_schema
      end
    end
  end

  path "/api/v1/notifications/read_all" do
    patch "Mark every inbox notification as read" do
      operationId "readAllNotifications"
      tags "Notifications"
      description "Marks all inbox unread as read. Empty body 204. Does not affect friendship_requested rows."
      security [ bearer_auth: [] ]
      documented_response "204", "all inbox notifications marked as read"
      documented_response "401", "authentication required" do
        schema error_schema
      end
    end
  end

  path "/api/v1/notifications/{id}" do
    parameter name: :id, in: :path, required: true, schema: { type: :integer, format: :int64 }
    delete "Delete an inbox notification" do
      operationId "deleteNotification"
      tags "Notifications"
      description "Destroys one inbox notification owned by current user. 204 empty. Missing/foreign/friendship_requested → 404."
      security [ bearer_auth: [] ]
      documented_response "204", "notification deleted"
      documented_response "401", "authentication required" do
        schema error_schema
      end
      documented_response "404", "inbox notification not found for current user", examples: [
        { name: :example, value: { error: { message: "Not found" } } }
      ] do
        schema error_schema
      end
    end
  end

  path "/api/v1/device_token" do
    post "Register a mobile push device token" do
      operationId "registerDeviceToken"
      tags "DeviceTokens"
      description "Registers an FCM token for the current user. Success 200 empty body (not 201). " \
                  "Reassigns the token if it already belonged to another account. " \
                  "platform android|ios (default android). No web platform. " \
                  "Call after signIn/confirmUser or FCM refresh. Canonical contract: docs/mobile/device_tokens/."
      security [ bearer_auth: [] ]
      consumes "application/json"
      parameter name: :device_token_payload, in: :body, required: true, schema: {
        type: :object,
        required: [ :device_token ],
        properties: {
          device_token: {
            type: :object,
            required: [ :token ],
            properties: {
              token: { type: :string, example: "fcm-abc" },
              platform: { type: :string, enum: %w[android ios], default: "android" }
            }
          }
        },
        example: { device_token: { token: "fcm-abc", platform: "android" } }
      }
      documented_response "200", "device token registered (empty body)"
      documented_response "401", "authentication required" do
        schema error_schema
      end
      documented_response "422", "validation failed", examples: [
        {
          name: :example,
          value: {
            error: {
              message: "Validation failed",
              details: { platform: [ "n'est pas inclus(e) dans la liste" ] }
            }
          }
        }
      ] do
        schema error_schema
      end
    end

    delete "Unregister a mobile push device token" do
      operationId "unregisterDeviceToken"
      tags "DeviceTokens"
      description "Removes the token for the current user. Always 204 (idempotent if missing). " \
                  "Call before signOut while JWT is still valid."
      security [ bearer_auth: [] ]
      consumes "application/json"
      parameter name: :device_token_payload, in: :body, required: true, schema: {
        type: :object,
        required: [ :device_token ],
        properties: {
          device_token: {
            type: :object,
            required: [ :token ],
            properties: {
              token: { type: :string, example: "fcm-abc" }
            }
          }
        },
        example: { device_token: { token: "fcm-abc" } }
      }
      documented_response "204", "device token removed (or already absent)"
      documented_response "401", "authentication required" do
        schema error_schema
      end
    end
  end
end
