# frozen_string_literal: true

require "swagger_helper"

# Documentation-only rswag metadata for Friendship mutations.
RSpec.describe "Api::V1 Friendships OpenAPI mutations", type: :request do
  include OpenapiContractHelpers

  error = { "$ref" => "#/components/schemas/Error" }
  friendship = { "$ref" => "#/components/schemas/Friendship" }
  ex = OpenapiFriendshipsExamples

  path "/api/v1/friendships/{id}" do
    parameter name: :id, in: :path, required: true, schema: { type: :integer, format: :int64, example: 10 }

    patch "Accept or decline a friendship request" do
      operationId "updateFriendship"
      tags "Friendships"
      description "Only the **receiver** of a **pending** Friendship may PATCH; otherwise 403. " \
                  "Body: `{ \"status\": \"accepted\" }` or `{ \"status\": \"declined\" }` (required enum). " \
                  "Runtime trap: if status is exactly `\"declined\"` → decline; **any other value** " \
                  "(including missing/garbage) takes the accept branch — clients must send only the enum. " \
                  "Accept → `accepted` (private event visibility + invites). Decline → `declined` " \
                  "(visible only in receiver `declined` bucket; cleans up friendship_requested). " \
                  "Cannot accept from declined — delete then createFriendship. " \
                  "Next: refetch listFriendships (`received` + `accepted` or `declined`)."
      security [ bearer_auth: [] ]
      consumes "application/json"
      produces "application/json"
      parameter name: :friendship_update, in: :body, required: true, schema: {
        type: :object,
        required: [ :status ],
        properties: {
          status: {
            type: :string,
            enum: %w[accepted declined],
            description: "Receiver-only transition from pending."
          }
        },
        example: { status: "accepted" }
      }
      documented_response "200", "friendship request updated",
                          examples: [
                            { name: :accepted, value: ex::ACCEPTED },
                            { name: :declined, value: ex::DECLINED }
                          ] do
        schema friendship
      end
      documented_response "401", "authentication required",
                          examples: [ { name: :unauthorized, value: ex::AUTH_ERROR_401 } ] do
        schema error
      end
      documented_response "403", "current user cannot transition this friendship",
                          examples: [ { name: :forbidden, value: ex::ERROR_403 } ] do
        schema error
      end
      documented_response "404", "friendship not found",
                          examples: [ { name: :not_found, value: ex::ERROR_404 } ] do
        schema error
      end
      documented_response "422", "friendship validation failed",
                          examples: [ { name: :validation, value: ex::ERROR_422_DUPLICATE } ] do
        schema error
      end
    end

    delete "Cancel, unfriend, or remove a declined friendship" do
      operationId "deleteFriendship"
      tags "Friendships"
      description "Destroy authz matrix (else 403; missing id → 404; success → 204 empty body): " \
                  "(1) sender + pending → cancel request; " \
                  "(2) sender or receiver + accepted → unfriend; " \
                  "(3) receiver + declined → remove declined (either party may then re-request). " \
                  "Receiver cannot delete pending; sender cannot delete declined. " \
                  "Cleans up friendship_requested notification when present. " \
                  "Next: refetch listFriendships."
      security [ bearer_auth: [] ]
      documented_response "204", "friendship deleted"
      documented_response "401", "authentication required",
                          examples: [ { name: :unauthorized, value: ex::AUTH_ERROR_401 } ] do
        schema error
      end
      documented_response "403", "current user cannot delete this friendship",
                          examples: [ { name: :forbidden, value: ex::ERROR_403 } ] do
        schema error
      end
      documented_response "404", "friendship not found",
                          examples: [ { name: :not_found, value: ex::ERROR_404 } ] do
        schema error
      end
    end
  end
end
