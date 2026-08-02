# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Api::V1 Passwords", type: :request do
  path "/api/v1/users/password" do
    post "Request password reset instructions" do
      operationId "requestPasswordReset"
      tags "Authentication"
      description "Emails reset instructions. Next: resetPassword with the email token."
      consumes "application/json"
      produces "application/json"
      parameter name: :password_request, in: :body, required: true, schema: {
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

      response "204", "reset instructions requested" do
        let(:user_record) { create(:user) }
        let(:password_request) { { user: { email: user_record.email } } }

        run_test! do
          expect(response.body).to be_blank
        end
      end

      response "422", "request validation failed" do
        schema "$ref" => "#/components/schemas/Error"
        examples "application/json" => {
          error: { message: "Validation failed", details: { email: [ "Email not found" ] } }
        }
        let(:password_request) { { user: { email: "missing@example.com" } } }

        run_test! do |response|
          expect(JSON.parse(response.body).dig("error", "message")).to eq("Validation failed")
        end
      end
    end

    patch "Reset a password with a token" do
      operationId "resetPassword"
      tags "Authentication"
      description "Sets a new password. Does not issue a JWT. Next: signIn with the new password."
      consumes "application/json"
      produces "application/json"
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
        },
        example: {
          user: {
            reset_password_token: "raw-token-from-email",
            password: "newpassword123",
            password_confirmation: "newpassword123"
          }
        }
      }

      response "204", "password reset" do
        let(:user_record) { create(:user) }
        let(:password_reset) do
          {
            user: {
              reset_password_token: raw_reset_password_token_for(user_record),
              password: "newpassword123",
              password_confirmation: "newpassword123"
            }
          }
        end

        run_test! do
          expect(response.body).to be_blank
          expect(response.headers["Authorization"]).to be_blank
        end
      end

      response "422", "reset validation failed" do
        schema "$ref" => "#/components/schemas/Error"
        examples "application/json" => {
          error: { message: "Validation failed",
                   details: { reset_password_token: [ "Reset password token is invalid" ] } }
        }
        let(:password_reset) do
          {
            user: {
              reset_password_token: "invalid",
              password: "newpassword123",
              password_confirmation: "newpassword123"
            }
          }
        end

        run_test! do |response|
          expect(JSON.parse(response.body).dig("error", "message")).to eq("Validation failed")
        end
      end
    end

    put "Reset a password (PUT alias)" do
      operationId "resetPasswordWithPut"
      tags "Authentication"
      description "Alias of resetPassword."
      consumes "application/json"
      parameter name: :password_reset, in: :body, required: true, schema: {
        type: :object, required: [ :user ],
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

      response "204", "password reset" do
        let(:user_record) { create(:user) }
        let(:token) { raw_reset_password_token_for(user_record) }
        let(:password_reset) do
          { user: { reset_password_token: token, password: "anotherpassword123",
                    password_confirmation: "anotherpassword123" } }
        end
        run_test!
      end
    end
  end
end
