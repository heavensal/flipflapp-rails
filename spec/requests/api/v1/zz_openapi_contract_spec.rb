# frozen_string_literal: true

require "swagger_helper"

# Documentation-only rswag metadata for non-Auth mobile contract paths.
# Auth OpenAPI is owned by executable specs (sessions/registrations/passwords/confirmations/users*).
RSpec.describe "Api::V1 complete OpenAPI contract", type: :request do
  include OpenapiContractHelpers

  error_schema = { "$ref" => "#/components/schemas/Error" }
  notification_schema = { "$ref" => "#/components/schemas/Notification" }

  # Friendships OpenAPI lives in openapi_friendships_spec.rb

  path "/api/v1/notifications" do
    get "List recent inbox notifications" do
      operationId "listNotifications"
      tags "Notifications"
      description "Returns at most 20 recent notifications and excludes friendship_requested. " \
                  "Friends-request UX is listFriendships.received (badge), not this inbox. " \
                  "Push for friendship_requested may still arrive — route to the friendships screen."
      security [ bearer_auth: [] ]
      produces "application/json"
      documented_response "200", "notifications listed" do
        schema type: :array, maxItems: 20, items: notification_schema
      end
      documented_response "401", "authentication required" do
        schema error_schema
      end
    end
  end

  path "/api/v1/notifications/{id}/read" do
    parameter name: :id, in: :path, required: true, schema: { type: :integer, format: :int64 }
    patch "Mark a notification as read" do
      operationId "readNotification"
      tags "Notifications"
      security [ bearer_auth: [] ]
      produces "application/json"
      documented_response "200", "notification marked as read" do
        schema notification_schema
      end
      documented_response "401", "authentication required" do
        schema error_schema
      end
      documented_response "404", "inbox notification not found for current user" do
        schema error_schema
      end
    end
  end

  path "/api/v1/notifications/read_all" do
    patch "Mark every inbox notification as read" do
      operationId "readAllNotifications"
      tags "Notifications"
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
      security [ bearer_auth: [] ]
      documented_response "204", "notification deleted"
      documented_response "401", "authentication required" do
        schema error_schema
      end
      documented_response "404", "inbox notification not found for current user" do
        schema error_schema
      end
    end
  end

  path "/api/v1/device_token" do
    post "Register a mobile push device token" do
      operationId "registerDeviceToken"
      tags "DeviceTokens"
      description "Registers an FCM (Android) or APNs-via-FCM (iOS) token for the current user. Reassigns the token if it already belonged to another account."
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
              token: { type: :string },
              platform: { type: :string, enum: %w[android ios], default: "android" }
            }
          }
        }
      }
      documented_response "200", "device token registered"
      documented_response "401", "authentication required" do
        schema error_schema
      end
      documented_response "422", "validation failed" do
        schema error_schema
      end
    end

    delete "Unregister a mobile push device token" do
      operationId "unregisterDeviceToken"
      tags "DeviceTokens"
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
              token: { type: :string }
            }
          }
        }
      }
      documented_response "204", "device token removed (or already absent)"
      documented_response "401", "authentication required" do
        schema error_schema
      end
    end
  end
end
