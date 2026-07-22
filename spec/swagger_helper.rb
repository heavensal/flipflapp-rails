# frozen_string_literal: true

require "rails_helper"

RSpec.configure do |config|
  config.openapi_root = Rails.root.join("swagger").to_s

  config.openapi_specs = {
    "v1/swagger.yaml" => {
      openapi: "3.0.1",
      info: {
        title: "FlipFlapp API V1",
        version: "v1",
        description: "JSON API for FlipFlapp iOS/Android clients. Resource names mirror the web app (Convention over Configuration)."
      },
      paths: {},
      components: {
        securitySchemes: {
          bearer_auth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: "JWT"
          }
        },
        schemas: {
          AuthenticationError: {
            type: :object,
            required: [ :error ],
            properties: {
              error: { type: :string, example: "You need to sign in or sign up before continuing." }
            }
          },
          Error: {
            type: :object,
            required: [ :error ],
            properties: {
              error: {
                type: :object,
                required: [ :message ],
                properties: {
                  message: { type: :string, example: "Validation failed" },
                  details: {
                    type: :object,
                    nullable: true,
                    additionalProperties: {
                      type: :array,
                      items: { type: :string }
                    },
                    example: { email: [ "Email has already been taken" ] }
                  }
                }
              }
            }
          },
          PublicUser: {
            type: :object,
            required: %i[id first_name last_name username avatar_url],
            properties: {
              id: { type: :integer, format: :int64 },
              first_name: { type: :string, nullable: true },
              last_name: { type: :string, nullable: true },
              username: { type: :string, nullable: true, example: "ada#0001" },
              avatar_url: { type: :string, format: :uri, nullable: true }
            }
          },
          CurrentUser: {
            allOf: [
              { "$ref" => "#/components/schemas/PublicUser" },
              {
                type: :object,
                required: %i[email role],
                properties: {
                  email: { type: :string, format: :email },
                  role: { type: :string, enum: %w[player admin] }
                }
              }
            ]
          },
          EventViewerContext: {
            type: :object,
            required: %i[participant can_invite author invited],
            properties: {
              participant: { type: :boolean },
              can_invite: { type: :boolean },
              author: { type: :boolean },
              invited: { type: :boolean }
            }
          },
          Event: {
            type: :object,
            required: %i[
              id title description location start_time number_of_participants price
              is_private latitude longitude user_id created_at updated_at participants_count
              spots_remaining fill_level user current_user
            ],
            properties: {
              id: { type: :integer, format: :int64 },
              title: { type: :string },
              description: { type: :string, nullable: true },
              location: { type: :string },
              start_time: { type: :string, format: :"date-time" },
              number_of_participants: { type: :integer, minimum: 1 },
              price: { type: :string, pattern: "^-?\\d+(?:\\.\\d+)?$", example: "10.0" },
              is_private: { type: :boolean },
              latitude: { type: :string, pattern: "^-?\\d+(?:\\.\\d+)?$", example: "48.856613" },
              longitude: { type: :string, pattern: "^-?\\d+(?:\\.\\d+)?$", example: "2.352222" },
              user_id: { type: :integer, format: :int64 },
              created_at: { type: :string, format: :"date-time" },
              updated_at: { type: :string, format: :"date-time" },
              participants_count: { type: :integer, minimum: 0 },
              spots_remaining: { type: :integer },
              fill_level: { type: :string, enum: %w[open tight full] },
              user: { "$ref" => "#/components/schemas/PublicUser" },
              current_user: {
                allOf: [ { "$ref" => "#/components/schemas/EventViewerContext" } ],
                nullable: true
              }
            }
          },
          EventTeam: {
            type: :object,
            required: %i[id event_id slot label created_at updated_at countable],
            properties: {
              id: { type: :integer, format: :int64 },
              event_id: { type: :integer, format: :int64 },
              slot: { type: :string, enum: %w[team_one team_two bench] },
              label: { type: :string },
              created_at: { type: :string, format: :"date-time" },
              updated_at: { type: :string, format: :"date-time" },
              countable: { type: :boolean }
            }
          },
          EventParticipant: {
            type: :object,
            required: %i[id event_id event_team_id user_id created_at updated_at user],
            properties: {
              id: { type: :integer, format: :int64 },
              event_id: { type: :integer, format: :int64 },
              event_team_id: { type: :integer, format: :int64 },
              user_id: { type: :integer, format: :int64 },
              created_at: { type: :string, format: :"date-time" },
              updated_at: { type: :string, format: :"date-time" },
              user: { "$ref" => "#/components/schemas/PublicUser" }
            }
          },
          Invitation: {
            type: :object,
            required: %i[id event_id user_id created_at updated_at user],
            properties: {
              id: { type: :integer, format: :int64 },
              event_id: { type: :integer, format: :int64 },
              user_id: { type: :integer, format: :int64 },
              created_at: { type: :string, format: :"date-time" },
              updated_at: { type: :string, format: :"date-time" },
              user: { "$ref" => "#/components/schemas/PublicUser" }
            }
          },
          Friendship: {
            type: :object,
            required: %i[id sender_id receiver_id status created_at updated_at sender receiver],
            properties: {
              id: { type: :integer, format: :int64 },
              sender_id: { type: :integer, format: :int64 },
              receiver_id: { type: :integer, format: :int64 },
              status: { type: :string, enum: %w[pending accepted declined] },
              created_at: { type: :string, format: :"date-time" },
              updated_at: { type: :string, format: :"date-time" },
              sender: { "$ref" => "#/components/schemas/PublicUser" },
              receiver: { "$ref" => "#/components/schemas/PublicUser" }
            }
          },
          FriendshipBuckets: {
            type: :object,
            required: %i[accepted sent received declined],
            properties: %i[accepted sent received declined].to_h do |bucket|
              [ bucket, { type: :array, items: { "$ref" => "#/components/schemas/Friendship" } } ]
            end
          },
          Notification: {
            type: :object,
            required: %i[id user_id kind read payload notifiable_type notifiable_id created_at updated_at],
            properties: {
              id: { type: :integer, format: :int64 },
              user_id: { type: :integer, format: :int64 },
              kind: {
                type: :string,
                enum: %w[updated canceled reminder joined left invited friendship_requested]
              },
              read: { type: :boolean },
              payload: { type: :object, additionalProperties: true },
              notifiable_type: { type: :string, nullable: true },
              notifiable_id: { type: :integer, format: :int64, nullable: true },
              created_at: { type: :string, format: :"date-time" },
              updated_at: { type: :string, format: :"date-time" }
            }
          },
          EventInput: {
            type: :object,
            properties: {
              title: { type: :string },
              description: { type: :string, nullable: true },
              location: { type: :string },
              start_time: { type: :string, format: :"date-time" },
              number_of_participants: { type: :integer, minimum: 1 },
              price: { type: :number, format: :double },
              is_private: { type: :boolean },
              latitude: { type: :number, format: :double },
              longitude: { type: :number, format: :double }
            }
          }
        }
      },
      servers: [
        {
          url: "http://{defaultHost}",
          variables: {
            defaultHost: {
              default: "localhost:3000"
            }
          }
        }
      ]
    }
  }

  config.openapi_format = :yaml
end
