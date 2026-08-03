# frozen_string_literal: true

require "swagger_helper"

# Documentation-only rswag metadata for Friendships (executable coverage in friendships_*_spec).
RSpec.describe "Api::V1 Friendships OpenAPI", type: :request do
  include OpenapiContractHelpers

  error = { "$ref" => "#/components/schemas/Error" }
  public_user = { "$ref" => "#/components/schemas/PublicUser" }
  friendship = { "$ref" => "#/components/schemas/Friendship" }
  ex = OpenapiFriendshipsExamples

  path "/api/v1/friendships" do
    get "List friendships grouped by state" do
      operationId "listFriendships"
      tags "Friendships"
      description "Return four always-present buckets for the current user: " \
                  "`accepted` (all accepted involving me), `sent` (pending where I am sender), " \
                  "`received` (pending where I am receiver), `declined` (declined where I am receiver only — " \
                  "sender is soft-ghosted). Empty arrays are returned, never omitted keys. " \
                  "Each Friendship includes nested PublicUser `sender` and `receiver`; pick the other user " \
                  "by comparing `me.id` to `sender_id`/`receiver_id`. " \
                  "Friends badge / unread requests UX = `received.length` (not notifications inbox). " \
                  "Next: updateFriendship / deleteFriendship, or invite-picker compose from `accepted`."
      security [ bearer_auth: [] ]
      produces "application/json"
      documented_response "200", "friendship buckets returned",
                          examples: [
                            { name: :buckets, value: ex::BUCKETS },
                            { name: :empty, value: ex::EMPTY_BUCKETS }
                          ] do
        schema "$ref" => "#/components/schemas/FriendshipBuckets"
      end
      documented_response "401", "authentication required",
                          examples: [ { name: :unauthorized, value: ex::AUTH_ERROR_401 } ] do
        schema error
      end
    end

    post "Send a friendship request" do
      operationId "createFriendship"
      tags "Friendships"
      description "Create a pending Friendship (`sender` = current user, `receiver` = `user_id`). " \
                  "Body is top-level `{ \"user_id\": <id> }` — not nested under `friendship`. " \
                  "Side effect: enqueues `friendship_requested` notification for the receiver " \
                  "(hidden from notifications inbox; may still push — route to friendships `received`). " \
                  "Fails 404 if user missing; 422 for self, duplicate pair, or reverse existing pair. " \
                  "Next: refetch `listFriendships` (`sent`); target disappears from search."
      security [ bearer_auth: [] ]
      consumes "application/json"
      produces "application/json"
      parameter name: :friendship_create, in: :body, required: true, schema: {
        type: :object,
        required: [ :user_id ],
        properties: {
          user_id: {
            type: :integer,
            format: :int64,
            description: "Receiver user id. Top-level key — not nested.",
            example: 2
          }
        },
        example: { user_id: 2 }
      }
      documented_response "201", "friendship request created",
                          examples: [ { name: :pending, value: ex::PENDING } ] do
        schema friendship
      end
      documented_response "401", "authentication required",
                          examples: [ { name: :unauthorized, value: ex::AUTH_ERROR_401 } ] do
        schema error
      end
      documented_response "404", "target user not found",
                          examples: [ { name: :not_found, value: ex::ERROR_404 } ] do
        schema error
      end
      documented_response "422", "friendship validation failed",
                          examples: [
                            { name: :self, value: ex::ERROR_422_SELF },
                            { name: :duplicate, value: ex::ERROR_422_DUPLICATE },
                            { name: :reverse, value: ex::ERROR_422_REVERSE }
                          ] do
        schema error
      end
    end
  end

  path "/api/v1/friendships/search" do
    get "Search users without an existing friendship" do
      operationId "searchFriendshipCandidates"
      tags "Friendships"
      description "Ransack candidates for a new request. Scope: `User.users_without_friendship` — " \
                  "excludes self and anyone with any Friendship row (pending/accepted/declined). " \
                  "Searchable attributes only: first_name, last_name, username — **not email**. " \
                  "If `q` is missing or blank → `200` with `[]` (not all users). " \
                  "Returns PublicUser[] (no email/role). Search selects limited columns so `avatar_url` " \
                  "is typically null. Example: " \
                  "`GET /api/v1/friendships/search?q[first_name_or_last_name_or_username_cont]=Zinedine`. " \
                  "Next: createFriendship with chosen `user_id`."
      security [ bearer_auth: [] ]
      produces "application/json"
      parameter name: :q, in: :query, required: false, style: :deepObject, explode: true, schema: {
        type: :object,
        description: "Ransack filter. Only first_name, last_name and username are searchable.",
        properties: {
          first_name_or_last_name_or_username_cont: {
            type: :string,
            example: "Zinedine"
          }
        },
        additionalProperties: false
      }
      documented_response "200", "matching users returned",
                          examples: [
                            { name: :hits, value: [ ex::SEARCH_HIT ] },
                            { name: :empty_query, value: [] }
                          ] do
        schema type: :array, items: public_user
      end
      documented_response "401", "authentication required",
                          examples: [ { name: :unauthorized, value: ex::AUTH_ERROR_401 } ] do
        schema error
      end
    end
  end
end
