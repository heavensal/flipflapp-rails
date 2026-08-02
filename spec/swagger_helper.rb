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
                required: %i[email unconfirmed_email role],
                properties: {
                  email: {
                    type: :string,
                    format: :email,
                    description: "Confirmed login email. Unchanged until a pending email change is confirmed."
                  },
                  unconfirmed_email: {
                    type: :string,
                    format: :email,
                    nullable: true,
                    description: "Pending email after PATCH /me; null when none. Confirm via Auth confirmUser."
                  },
                  role: {
                    type: :string,
                    enum: %w[player admin],
                    description: "Informational for player apps; no mobile admin API in MVP."
                  }
                }
              }
            ]
          },
          EventViewerContext: {
            type: :object,
            required: %i[participant can_invite author invited],
            properties: {
              participant: { type: :boolean, description: "Viewer has joined the event." },
              can_invite: { type: :boolean, description: "Viewer may invite accepted friends." },
              author: { type: :boolean, description: "Viewer created the event." },
              invited: { type: :boolean, description: "Viewer has a pending invitation." }
            }
          },
          Event: {
            type: :object,
            description: "Upcoming football event. GET /api/v1/events returns visible upcoming events; show includes current_user viewer context when authenticated.",
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
              price: {
                type: :string,
                pattern: "^-?\\d+(?:\\.\\d+)?$",
                example: "10.0",
                description: "Serialized as decimal string in responses; send as number in create/update requests."
              },
              is_private: { type: :boolean },
              latitude: {
                type: :string,
                pattern: "^-?\\d+(?:\\.\\d+)?$",
                example: "48.856613",
                description: "Serialized as decimal string in responses; send as number in create/update requests."
              },
              longitude: {
                type: :string,
                pattern: "^-?\\d+(?:\\.\\d+)?$",
                example: "2.352222",
                description: "Serialized as decimal string in responses; send as number in create/update requests."
              },
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
            description: "Squad slot for an Event. Exactly three per event (team_one, team_two, bench). " \
                         "slot is immutable identity; label is display-only (renameable on countable teams). " \
                         "countable true only for team_one/team_two (bench never counts toward Event capacity). " \
                         "No nested roster — use listEventTeamParticipants. No POST/DELETE event_teams.",
            required: %i[id event_id slot label created_at updated_at countable],
            properties: {
              id: { type: :integer, format: :int64 },
              event_id: { type: :integer, format: :int64 },
              slot: {
                type: :string,
                enum: %w[team_one team_two bench],
                description: "Immutable squad identity. Domain capacity and notifications key off slot, never label."
              },
              label: {
                type: :string,
                maxLength: 24,
                description: "Display name. Letters, digits, spaces only (Unicode alnum). " \
                             "Server strips/collapses whitespace. Unique case-insensitively within the event. " \
                             "Defaults at Event create from I18n (en: Team 1 / Team 2 / On the bench; " \
                             "fr: Equipe 1 / Equipe 2 / Sur le Banc)."
              },
              created_at: { type: :string, format: :"date-time" },
              updated_at: { type: :string, format: :"date-time" },
              countable: {
                type: :boolean,
                description: "true for team_one and team_two; false for bench. Only countable teams count toward participants_count."
              }
            },
            example: {
              id: 10,
              event_id: 42,
              slot: "team_one",
              label: "Bleus",
              created_at: "2026-08-02T10:00:00.000Z",
              updated_at: "2026-08-02T10:00:00.000Z",
              countable: true
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
            description: "Link between two users. Status machine: pending → accepted|declined; " \
                         "destroy rules differ by role (cancel / unfriend / remove declined). " \
                         "Mobile picks the other user by comparing current user id to sender_id/receiver_id. " \
                         "Accepted enables private event visibility and invites; pending/declined do not.",
            required: %i[id sender_id receiver_id status created_at updated_at sender receiver],
            properties: {
              id: { type: :integer, format: :int64 },
              sender_id: { type: :integer, format: :int64 },
              receiver_id: { type: :integer, format: :int64 },
              status: {
                type: :string,
                enum: %w[pending accepted declined],
                description: "pending: request open; accepted: friends; declined: soft reject " \
                             "(receiver-only visibility in index declined bucket)."
              },
              created_at: { type: :string, format: :"date-time" },
              updated_at: { type: :string, format: :"date-time" },
              sender: { "$ref" => "#/components/schemas/PublicUser" },
              receiver: { "$ref" => "#/components/schemas/PublicUser" }
            },
            example: {
              id: 10,
              sender_id: 1,
              receiver_id: 2,
              status: "pending",
              created_at: "2026-08-02T10:00:00.000Z",
              updated_at: "2026-08-02T10:00:00.000Z",
              sender: {
                id: 1,
                first_name: "Ada",
                last_name: "Lovelace",
                username: "ada#0001",
                avatar_url: "https://cdn.flipflapp.test/avatars/ada-0001/medium.jpg"
              },
              receiver: {
                id: 2,
                first_name: "Grace",
                last_name: "Hopper",
                username: "grace#0002",
                avatar_url: nil
              }
            }
          },
          FriendshipBuckets: {
            type: :object,
            description: "Asymmetric index for the current user. Keys always present (use empty arrays). " \
                         "accepted: all accepted involving me; sent: pending I sent; received: pending I received; " \
                         "declined: declined where I am receiver only.",
            required: %i[accepted sent received declined],
            properties: %i[accepted sent received declined].to_h do |bucket|
              [ bucket, { type: :array, items: { "$ref" => "#/components/schemas/Friendship" } } ]
            end,
            example: {
              accepted: [],
              sent: [
                {
                  id: 10,
                  sender_id: 1,
                  receiver_id: 2,
                  status: "pending",
                  created_at: "2026-08-02T10:00:00.000Z",
                  updated_at: "2026-08-02T10:00:00.000Z",
                  sender: {
                    id: 1, first_name: "Ada", last_name: "Lovelace",
                    username: "ada#0001", avatar_url: nil
                  },
                  receiver: {
                    id: 2, first_name: "Grace", last_name: "Hopper",
                    username: "grace#0002", avatar_url: nil
                  }
                }
              ],
              received: [],
              declined: []
            }
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
          },
          EventCreateInput: {
            type: :object,
            required: %i[title location start_time number_of_participants price latitude longitude],
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
