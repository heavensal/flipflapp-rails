# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Api::V1 Registrations", type: :request do
  path "/api/v1/users" do
    post "Register an unconfirmed user" do
      operationId "registerUser"
      tags "Authentication"
      description "Creates an unconfirmed account and sends a confirmation email. Does not issue a JWT. Next: confirmUser with the email token."
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
        },
        example: {
          user: {
            email: "new.player@example.com",
            password: "password123",
            password_confirmation: "password123",
            first_name: "Ada",
            last_name: "Lovelace"
          }
        }
      }

      response "201", "user registered (unconfirmed, no session)" do
        schema "$ref" => "#/components/schemas/CurrentUser"
        examples "application/json" => {
            id: 1, email: "new.player@example.com", first_name: "Ada", last_name: "Lovelace",
            username: "ada#0001", role: "player", unconfirmed_email: nil, avatar_url: nil
        }
        let(:registration) do
          {
            user: {
              email: "new.player@example.com",
              password: "password123",
              password_confirmation: "password123",
              first_name: "Ada",
              last_name: "Lovelace"
            }
          }
        end

        run_test! do |response|
          expect(response.headers["Authorization"]).to be_blank
          expect(JSON.parse(response.body)).to include("email" => "new.player@example.com")
          expect(User.find_by!(email: "new.player@example.com")).not_to be_confirmed
        end
      end

      response "422", "registration validation failed" do
        schema "$ref" => "#/components/schemas/Error"
        examples "application/json" => {
            error: {
              message: "Validation failed",
              details: { email: [ "Email has already been taken" ] }
            }
        }
        let!(:existing) { create(:user, email: "taken@example.com") }
        let(:registration) do
          {
            user: {
              email: existing.email,
              password: "password123",
              password_confirmation: "password123",
              first_name: "Ada",
              last_name: "Lovelace"
            }
          }
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.dig("error", "message")).to eq("Validation failed")
          expect(body.dig("error", "details")).to be_present
        end
      end
    end
  end
end
