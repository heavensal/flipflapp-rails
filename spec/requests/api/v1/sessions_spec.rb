# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Api::V1 Sessions", type: :request do
  path "/api/v1/users/sign_in" do
    post "Sign in a confirmed user and issue a JWT" do
      operationId "signIn"
      tags "Authentication"
      description "Authenticates a confirmed user. Persist Authorization from the response header. Unconfirmed accounts receive 401."
      consumes "application/json"
      produces "application/json"
      parameter name: :user, in: :body, required: true, schema: {
        type: :object,
        required: [ :user ],
        properties: {
          user: {
            type: :object,
            required: %w[email password],
            properties: {
              email: { type: :string, format: :email },
              password: { type: :string, format: :password }
            }
          }
        },
        example: { user: { email: "ada@example.com", password: "password123" } }
      }

      response "200", "signed in" do
        schema "$ref" => "#/components/schemas/CurrentUser"
        header "Authorization", schema: { type: :string },
               description: "Bearer JWT for authenticated requests"
        examples "application/json" => {
            id: 1, email: "ada@example.com", first_name: "Ada", last_name: "Lovelace",
            username: "ada#0001", role: "player", unconfirmed_email: nil, avatar_url: nil
        }
        let(:user_record) { create(:user) }
        let(:user) { { user: { email: user_record.email, password: "password123" } } }

        run_test! do |response|
          expect(response.headers["Authorization"]).to be_present
          body = JSON.parse(response.body)
          expect(body).to include("email" => user_record.email)
          expect(body["error"]).to be_nil
        end
      end

      response "401", "invalid credentials or unconfirmed" do
        schema "$ref" => "#/components/schemas/Error"
        examples "application/json" => {
          error: { message: "Invalid Email or password." }
        }
        let(:user) { { user: { email: "nope@example.com", password: "wrong" } } }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.dig("error", "message")).to be_present
          expect(body["error"]).to be_a(Hash)
        end
      end
    end
  end

  path "/api/v1/users/sign_out" do
    delete "Sign out and revoke the JWT when present" do
      operationId "signOut"
      tags "Authentication"
      description "Always returns 204. When Authorization is present, the JWT is revoked via jwt_denylist."
      security [ { bearer_auth: [] } ]
      produces "application/json"

      response "204", "signed out" do
        let(:user_record) { create(:user) }
        let(:Authorization) { api_auth_headers_for(user_record)["Authorization"] }

        run_test! do
          expect(response.body).to be_blank
        end
      end
    end
  end

  describe "POST /api/v1/users/sign_in unconfirmed" do
    it "rejects unconfirmed users with a nested error" do
      user = create(:user, :unconfirmed)
      post "/api/v1/users/sign_in",
           params: { user: { email: user.email, password: "password123" } },
           as: :json

      expect(response).to have_http_status(:unauthorized)
      body = JSON.parse(response.body)
      expect(body.dig("error", "message")).to match(/confirm/i)
    end
  end

  describe "DELETE /api/v1/users/sign_out without token" do
    it "returns 204" do
      delete "/api/v1/users/sign_out", as: :json
      expect(response).to have_http_status(:no_content)
    end
  end
end
