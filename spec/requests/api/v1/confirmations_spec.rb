# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Api::V1 Confirmations", type: :request do
  path "/api/v1/users/confirmation" do
    post "Resend confirmation instructions" do
      operationId "resendConfirmation"
      tags "Authentication"
      description "Resends signup or reconfirmable email instructions. Next: confirmUser with the new token."
      consumes "application/json"
      produces "application/json"
      parameter name: :confirmation, in: :body, required: true, schema: {
        type: :object,
        required: [ :user ],
        properties: {
          user: {
            type: :object,
            required: [ :email ],
            properties: { email: { type: :string, format: :email } }
          }
        },
        example: { user: { email: "ada@example.com" } }
      }

      response "204", "confirmation instructions requested" do
        let(:user_record) { create(:user, :unconfirmed) }
        let(:confirmation) { { user: { email: user_record.email } } }

        run_test! do
          expect(response.body).to be_blank
        end
      end

      response "422", "request validation failed" do
        schema "$ref" => "#/components/schemas/Error"
        examples "application/json" => {
          error: {
            message: "Validation failed",
            details: { email: [ "Email was already confirmed, please try signing in" ] }
          }
        }
        let(:user_record) { create(:user) }
        let(:confirmation) { { user: { email: user_record.email } } }

        run_test! do |response|
          expect(JSON.parse(response.body).dig("error", "message")).to eq("Validation failed")
        end
      end
    end

    patch "Confirm account or email change with a token" do
      operationId "confirmUser"
      tags "Authentication"
      description "Confirms the account (or pending unconfirmed_email) and issues a JWT. Persist Authorization from the response."
      consumes "application/json"
      produces "application/json"
      parameter name: :confirmation, in: :body, required: true, schema: {
        type: :object,
        required: [ :user ],
        properties: {
          user: {
            type: :object,
            required: [ :confirmation_token ],
            properties: { confirmation_token: { type: :string } }
          }
        },
        example: { user: { confirmation_token: "raw-token-from-email" } }
      }

      response "200", "confirmed and signed in" do
        schema "$ref" => "#/components/schemas/CurrentUser"
        header "Authorization", schema: { type: :string },
               description: "Bearer JWT for authenticated requests"
        examples "application/json" => {
            id: 1, email: "ada@example.com", first_name: "Ada", last_name: "Lovelace",
            username: "ada#0001", role: "player", unconfirmed_email: nil, avatar_url: nil
        }
        let(:user_record) { create(:user, :unconfirmed) }
        let(:confirmation) do
          { user: { confirmation_token: raw_confirmation_token_for(user_record) } }
        end

        run_test! do |response|
          expect(response.headers["Authorization"]).to be_present
          expect(user_record.reload).to be_confirmed
          expect(JSON.parse(response.body)).to include("email" => user_record.email)
        end
      end

      response "422", "confirmation validation failed" do
        schema "$ref" => "#/components/schemas/Error"
        examples "application/json" => {
            error: {
              message: "Validation failed",
              details: { confirmation_token: [ "Confirmation token is invalid" ] }
            }
        }
        let(:confirmation) { { user: { confirmation_token: "invalid" } } }

        run_test! do |response|
          expect(JSON.parse(response.body).dig("error", "message")).to eq("Validation failed")
        end
      end
    end
  end
end
