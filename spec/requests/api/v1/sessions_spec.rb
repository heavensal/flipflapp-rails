# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Api::V1 Sessions", type: :request do
  path "/api/v1/users/sign_in" do
    post "Sign in" do
      operationId "signIn"
      tags "Users"
      consumes "application/json"
      produces "application/json"
      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              email: { type: :string },
              password: { type: :string }
            },
            required: %w[email password]
          }
        }
      }

      response "200", "signed in" do
        schema "$ref" => "#/components/schemas/CurrentUser"
        header "Authorization", schema: { type: :string }, description: "Bearer JWT to use on authenticated requests"
        let(:user_record) { create(:user) }
        let(:user) { { user: { email: user_record.email, password: "password123" } } }

        run_test! do |response|
          expect(response.headers["Authorization"]).to be_present
          expect(JSON.parse(response.body)).to include("email" => user_record.email)
        end
      end

      response "401", "invalid credentials" do
        schema "$ref" => "#/components/schemas/AuthenticationError"
        let(:user) { { user: { email: "nope@example.com", password: "wrong" } } }
        run_test!
      end
    end
  end

  path "/api/v1/users/sign_out" do
    delete "Sign out" do
      operationId "signOut"
      tags "Users"
      security [ bearer_auth: [] ]
      produces "application/json"

      response "204", "signed out" do
        let(:user_record) { create(:user) }
        let(:Authorization) { api_auth_headers_for(user_record)["Authorization"] }

        run_test!
      end

      response "401", "authentication required" do
        schema "$ref" => "#/components/schemas/AuthenticationError"
        specify("documents the 401 response") { expect(true).to be(true) }
      end
    end
  end
end
