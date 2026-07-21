# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Api::V1 Sessions", type: :request do
  path "/api/v1/users/sign_in" do
    post "Sign in" do
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
        let(:user_record) { create(:user) }
        let(:user) { { user: { email: user_record.email, password: "password123" } } }

        run_test! do |response|
          expect(response.headers["Authorization"]).to be_present
          expect(JSON.parse(response.body)).to include("email" => user_record.email)
        end
      end

      response "401", "invalid credentials" do
        let(:user) { { user: { email: "nope@example.com", password: "wrong" } } }
        run_test!
      end
    end
  end

  path "/api/v1/users/sign_out" do
    delete "Sign out" do
      tags "Users"
      security [ bearer_auth: [] ]
      produces "application/json"

      response "204", "signed out" do
        let(:user_record) { create(:user) }
        let(:Authorization) { api_auth_headers_for(user_record)["Authorization"] }

        run_test!
      end
    end
  end
end
