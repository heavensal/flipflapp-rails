# frozen_string_literal: true

require "swagger_helper"

# Documentation-only rswag metadata for the complete mobile contract. Executable
# behavior remains covered by the focused request specs in this directory.
RSpec.describe "Api::V1 complete OpenAPI contract", type: :request do
  def self.documented_response(status, description, &definition)
    response status, description do
      class_exec(&definition) if definition
      specify("documents the #{status} response") { expect(status).to match(/\A\d{3}\z/) }
    end
  end

  error_schema = { "$ref" => "#/components/schemas/Error" }
  authentication_error_schema = { "$ref" => "#/components/schemas/AuthenticationError" }
  current_user_schema = { "$ref" => "#/components/schemas/CurrentUser" }
  public_user_schema = { "$ref" => "#/components/schemas/PublicUser" }
  event_schema = { "$ref" => "#/components/schemas/Event" }
  event_team_schema = { "$ref" => "#/components/schemas/EventTeam" }
  participant_schema = { "$ref" => "#/components/schemas/EventParticipant" }
  invitation_schema = { "$ref" => "#/components/schemas/Invitation" }
  friendship_schema = { "$ref" => "#/components/schemas/Friendship" }
  notification_schema = { "$ref" => "#/components/schemas/Notification" }

  path "/api/v1/users" do
    post "Register a user" do
      operationId "registerUser"
      tags "Authentication"
      consumes "application/json"
      produces "application/json"
      parameter name: :registration, in: :body, required: true, schema: {
        type: :object,
        required: [ :user ],
        properties: {
          user: {
            type: :object,
            required: %i[email password password_confirmation first_name last_name],
            properties: {
              email: { type: :string, format: :email },
              password: { type: :string, format: :password, minLength: 6 },
              password_confirmation: { type: :string, format: :password },
              first_name: { type: :string },
              last_name: { type: :string },
              avatar: { type: :string, nullable: true, description: "CarrierWave upload value" }
            }
          }
        }
      }
      documented_response "201", "user registered" do
        schema current_user_schema
      end
      documented_response "422", "registration validation failed" do
        schema error_schema
      end
    end
  end

  path "/api/v1/users/password" do
    post "Request password reset instructions" do
      operationId "requestPasswordReset"
      tags "Authentication"
      consumes "application/json"
      parameter name: :password_request, in: :body, required: true, schema: {
        type: :object,
        required: [ :user ],
        properties: {
          user: {
            type: :object,
            required: [ :email ],
            properties: { email: { type: :string, format: :email } }
          }
        }
      }
      documented_response "204", "reset instructions requested"
      documented_response "422", "request validation failed" do
        schema error_schema
      end
    end

    patch "Reset a password" do
      operationId "resetPassword"
      tags "Authentication"
      consumes "application/json"
      parameter name: :password_reset, in: :body, required: true, schema: {
        type: :object,
        required: [ :user ],
        properties: {
          user: {
            type: :object,
            required: %i[reset_password_token password password_confirmation],
            properties: {
              reset_password_token: { type: :string },
              password: { type: :string, format: :password, minLength: 6 },
              password_confirmation: { type: :string, format: :password }
            }
          }
        }
      }
      documented_response "204", "password reset"
      documented_response "422", "reset validation failed" do
        schema error_schema
      end
    end

    put "Reset a password" do
      operationId "resetPasswordWithPut"
      tags "Authentication"
      consumes "application/json"
      parameter name: :password_reset, in: :body, required: true, schema: {
        type: :object,
        required: [ :user ],
        properties: {
          user: {
            type: :object,
            required: %i[reset_password_token password password_confirmation],
            properties: {
              reset_password_token: { type: :string },
              password: { type: :string, format: :password, minLength: 6 },
              password_confirmation: { type: :string, format: :password }
            }
          }
        }
      }
      documented_response "204", "password reset"
      documented_response "422", "reset validation failed" do
        schema error_schema
      end
    end
  end

  path "/api/v1/users/confirmation" do
    post "Resend confirmation instructions" do
      operationId "resendConfirmation"
      tags "Authentication"
      consumes "application/json"
      parameter name: :confirmation, in: :body, required: true, schema: {
        type: :object,
        required: [ :user ],
        properties: {
          user: {
            type: :object,
            required: [ :email ],
            properties: { email: { type: :string, format: :email } }
          }
        }
      }
      documented_response "204", "confirmation instructions requested"
      documented_response "422", "request validation failed" do
        schema error_schema
      end
    end
  end

  path "/api/v1/me" do
    patch "Update the current user" do
      operationId "updateCurrentUser"
      tags "Users"
      security [ bearer_auth: [] ]
      consumes "application/json"
      produces "application/json"
      parameter name: :profile, in: :body, required: true, schema: {
        type: :object,
        required: [ :user ],
        properties: {
          user: {
            type: :object,
            properties: {
              first_name: { type: :string },
              last_name: { type: :string },
              avatar: { type: :string, nullable: true, description: "CarrierWave upload value" },
              email: { type: :string, format: :email },
              password: { type: :string, format: :password },
              password_confirmation: { type: :string, format: :password }
            }
          }
        }
      }
      documented_response "200", "current user updated" do
        schema current_user_schema
      end
      documented_response "401", "authentication required" do
        schema authentication_error_schema
      end
      documented_response "422", "profile validation failed" do
        schema error_schema
      end
    end
  end

  path "/api/v1/users/{id}" do
    parameter name: :id, in: :path, required: true, schema: { type: :integer, format: :int64 }
    get "Show a public user profile" do
      operationId "getUser"
      tags "Users"
      security [ bearer_auth: [] ]
      produces "application/json"
      documented_response "200", "user found" do
        schema public_user_schema
      end
      documented_response "401", "authentication required" do
        schema authentication_error_schema
      end
      documented_response "404", "user not found" do
        schema error_schema
      end
    end
  end

  path "/api/v1/events/{id}" do
    parameter name: :id, in: :path, required: true, schema: { type: :integer, format: :int64 }
    patch "Update an event" do
      operationId "updateEvent"
      tags "Events"
      security [ bearer_auth: [] ]
      consumes "application/json"
      produces "application/json"
      parameter name: :event_update, in: :body, required: true, schema: {
        type: :object,
        required: [ :event ],
        properties: { event: { "$ref" => "#/components/schemas/EventInput" } }
      }
      documented_response "200", "event updated" do
        schema event_schema
      end
      documented_response "401", "authentication required" do
        schema authentication_error_schema
      end
      documented_response "403", "only the event author may update it" do
        schema error_schema
      end
      documented_response "404", "event missing or not viewable" do
        schema error_schema
      end
      documented_response "422", "event validation failed" do
        schema error_schema
      end
    end

    delete "Delete an event" do
      operationId "deleteEvent"
      tags "Events"
      security [ bearer_auth: [] ]
      documented_response "204", "event deleted"
      documented_response "401", "authentication required" do
        schema authentication_error_schema
      end
      documented_response "403", "only the event author may delete it" do
        schema error_schema
      end
      documented_response "404", "event missing or not viewable" do
        schema error_schema
      end
    end
  end

  path "/api/v1/events/{event_id}/event_teams/{id}" do
    parameter name: :event_id, in: :path, required: true, schema: { type: :integer, format: :int64 }
    parameter name: :id, in: :path, required: true, schema: { type: :integer, format: :int64 }
    get "Show an event team" do
      operationId "getEventTeam"
      tags "Event teams"
      security [ bearer_auth: [] ]
      produces "application/json"
      documented_response "200", "event team found" do
        schema event_team_schema
      end
      documented_response "401", "authentication required" do
        schema authentication_error_schema
      end
      documented_response "404", "event or team missing or not viewable" do
        schema error_schema
      end
    end

    patch "Rename a countable event team" do
      operationId "updateEventTeam"
      tags "Event teams"
      security [ bearer_auth: [] ]
      consumes "application/json"
      produces "application/json"
      parameter name: :event_team_update, in: :body, required: true, schema: {
        type: :object,
        required: [ :event_team ],
        properties: {
          event_team: {
            type: :object,
            required: [ :label ],
            properties: { label: { type: :string, maxLength: 24 } }
          }
        }
      }
      documented_response "200", "event team renamed" do
        schema event_team_schema
      end
      documented_response "401", "authentication required" do
        schema authentication_error_schema
      end
      documented_response "403", "user is not a participant or team is the bench" do
        schema error_schema
      end
      documented_response "404", "event or team missing or not viewable" do
        schema error_schema
      end
      documented_response "422", "team validation failed" do
        schema error_schema
      end
    end
  end

  path "/api/v1/events/{event_id}/event_participants" do
    parameter name: :event_id, in: :path, required: true, schema: { type: :integer, format: :int64 }
    get "List event participants" do
      operationId "listEventParticipants"
      tags "Event participants"
      security [ bearer_auth: [] ]
      produces "application/json"
      documented_response "200", "participants listed" do
        schema type: :array, items: participant_schema
      end
      documented_response "401", "authentication required" do
        schema authentication_error_schema
      end
      documented_response "404", "event missing or not viewable" do
        schema error_schema
      end
    end

    post "Join an event or switch team" do
      operationId "joinEvent"
      tags "Event participants"
      security [ bearer_auth: [] ]
      consumes "application/json"
      produces "application/json"
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
      documented_response "200", "existing participation moved to another team" do
        schema participant_schema
      end
      documented_response "201", "event joined" do
        schema participant_schema
      end
      documented_response "401", "authentication required" do
        schema authentication_error_schema
      end
      documented_response "404", "event is not joinable or team does not belong to event" do
        schema error_schema
      end
      documented_response "422", "participation validation failed or team is full" do
        schema error_schema
      end
    end
  end

  path "/api/v1/event_participants/{id}" do
    parameter name: :id, in: :path, required: true, schema: { type: :integer, format: :int64 }
    delete "Leave an event" do
      operationId "leaveEvent"
      tags "Event participants"
      security [ bearer_auth: [] ]
      documented_response "204", "participation deleted"
      documented_response "401", "authentication required" do
        schema authentication_error_schema
      end
      documented_response "404", "participation not found for current user" do
        schema error_schema
      end
    end
  end

  path "/api/v1/events/{event_id}/invitations" do
    parameter name: :event_id, in: :path, required: true, schema: { type: :integer, format: :int64 }
    get "List event invitations" do
      operationId "listInvitations"
      tags "Invitations"
      security [ bearer_auth: [] ]
      produces "application/json"
      documented_response "200", "invitations listed" do
        schema type: :array, items: invitation_schema
      end
      documented_response "401", "authentication required" do
        schema authentication_error_schema
      end
      documented_response "404", "event missing or not viewable" do
        schema error_schema
      end
    end

    post "Invite accepted friends to an event" do
      operationId "createInvitations"
      tags "Invitations"
      security [ bearer_auth: [] ]
      consumes "application/json"
      produces "application/json"
      parameter name: :invitations, in: :body, required: true, schema: {
        type: :object,
        required: [ :user_ids ],
        properties: {
          user_ids: {
            type: :array,
            minItems: 1,
            uniqueItems: true,
            items: { type: :integer, format: :int64 }
          }
        }
      }
      documented_response "201", "friends invited" do
        schema type: :array, items: invitation_schema
      end
      documented_response "401", "authentication required" do
        schema authentication_error_schema
      end
      documented_response "403", "current user is not an event participant" do
        schema error_schema
      end
      documented_response "404", "event missing or not viewable" do
        schema error_schema
      end
      documented_response "422", "no eligible users supplied" do
        schema error_schema
      end
    end
  end

  path "/api/v1/friendships" do
    get "List friendships grouped by state" do
      operationId "listFriendships"
      tags "Friendships"
      security [ bearer_auth: [] ]
      produces "application/json"
      documented_response "200", "friendship buckets returned" do
        schema "$ref" => "#/components/schemas/FriendshipBuckets"
      end
      documented_response "401", "authentication required" do
        schema authentication_error_schema
      end
    end

    post "Send a friendship request" do
      operationId "createFriendship"
      tags "Friendships"
      security [ bearer_auth: [] ]
      consumes "application/json"
      produces "application/json"
      parameter name: :friendship, in: :body, required: true, schema: {
        type: :object,
        required: [ :user_id ],
        properties: { user_id: { type: :integer, format: :int64 } }
      }
      documented_response "201", "friendship request created" do
        schema friendship_schema
      end
      documented_response "401", "authentication required" do
        schema authentication_error_schema
      end
      documented_response "404", "target user not found" do
        schema error_schema
      end
      documented_response "422", "friendship validation failed" do
        schema error_schema
      end
    end
  end

  path "/api/v1/friendships/search" do
    get "Search users without an existing friendship" do
      operationId "searchFriendshipCandidates"
      tags "Friendships"
      security [ bearer_auth: [] ]
      produces "application/json"
      parameter name: :q, in: :query, required: false, style: :deepObject, explode: true, schema: {
        type: :object,
        description: "Ransack filter. Only first_name, last_name and username are searchable.",
        properties: {
          first_name_or_last_name_or_username_cont: { type: :string }
        },
        additionalProperties: false
      }
      documented_response "200", "matching users returned" do
        schema type: :array, items: public_user_schema
      end
      documented_response "401", "authentication required" do
        schema authentication_error_schema
      end
    end
  end

  path "/api/v1/friendships/{id}" do
    parameter name: :id, in: :path, required: true, schema: { type: :integer, format: :int64 }
    patch "Accept or decline a friendship request" do
      operationId "updateFriendship"
      tags "Friendships"
      security [ bearer_auth: [] ]
      consumes "application/json"
      produces "application/json"
      parameter name: :friendship_update, in: :body, required: true, schema: {
        type: :object,
        required: [ :status ],
        properties: { status: { type: :string, enum: %w[accepted declined] } }
      }
      documented_response "200", "friendship request updated" do
        schema friendship_schema
      end
      documented_response "401", "authentication required" do
        schema authentication_error_schema
      end
      documented_response "403", "current user cannot transition this friendship" do
        schema error_schema
      end
      documented_response "404", "friendship not found" do
        schema error_schema
      end
      documented_response "422", "friendship validation failed" do
        schema error_schema
      end
    end

    delete "Cancel, remove or delete a friendship" do
      operationId "deleteFriendship"
      tags "Friendships"
      security [ bearer_auth: [] ]
      documented_response "204", "friendship deleted"
      documented_response "401", "authentication required" do
        schema authentication_error_schema
      end
      documented_response "403", "current user cannot delete this friendship" do
        schema error_schema
      end
      documented_response "404", "friendship not found" do
        schema error_schema
      end
    end
  end

  path "/api/v1/notifications" do
    get "List recent inbox notifications" do
      operationId "listNotifications"
      tags "Notifications"
      description "Returns at most 20 recent notifications and excludes friendship_requested."
      security [ bearer_auth: [] ]
      produces "application/json"
      documented_response "200", "notifications listed" do
        schema type: :array, maxItems: 20, items: notification_schema
      end
      documented_response "401", "authentication required" do
        schema authentication_error_schema
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
        schema authentication_error_schema
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
        schema authentication_error_schema
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
        schema authentication_error_schema
      end
      documented_response "404", "inbox notification not found for current user" do
        schema error_schema
      end
    end
  end
end
