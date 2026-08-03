# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Api::V1 Users", type: :request do
  path "/api/v1/users/{id}" do
    parameter name: :id, in: :path, required: true, schema: { type: :integer, format: :int64 }

    get "Show a public user profile" do
      operationId "getUser"
      tags "Users"
      description "PublicUser only — never email, role, or unconfirmed_email. " \
                  "Bearer required. Friendship status is not embedded; compose via Friendships. " \
                  "Full profile contract: docs/mobile/users/."
      produces "application/json"
      security [ { bearer_auth: [] } ]

      response "200", "user found" do
        schema "$ref" => "#/components/schemas/PublicUser"
        examples "application/json" => {
          id: 2, first_name: "Grace", last_name: "Hopper",
          username: "grace#0001", avatar_url: nil
        }
        let(:user_record) { create(:user) }
        let(:other) { create(:user) }
        let(:id) { other.id }
        let(:Authorization) { api_auth_headers_for(user_record)["Authorization"] }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body).to include("id" => other.id, "username" => other.username)
          expect(body.keys).not_to include("email", "role", "unconfirmed_email")
        end
      end

      response "401", "authentication required" do
        schema "$ref" => "#/components/schemas/Error"
        examples "application/json" => {
          error: { message: "Vous devez vous connecter ou vous inscrire pour continuer." }
        }
        let(:id) { 1 }
        let(:Authorization) { nil }
        run_test!
      end

      response "404", "user not found" do
        schema "$ref" => "#/components/schemas/Error"
        examples "application/json" => {
          error: { message: "Not found" }
        }
        let(:user_record) { create(:user) }
        let(:id) { 0 }
        let(:Authorization) { api_auth_headers_for(user_record)["Authorization"] }
        run_test! do |response|
          expect(JSON.parse(response.body).dig("error", "message")).to eq("Not found")
        end
      end
    end
  end
end
