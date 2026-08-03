# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Api::V1 Me", type: :request do
  path "/api/v1/me" do
    get "Return the authenticated profile" do
      operationId "getCurrentUser"
      tags "Users"
      description "Bootstrap CurrentUser after Auth. Never issues JWT. " \
                  "Includes unconfirmed_email (nullable) for pending reconfirmable email changes."
      produces "application/json"
      security [ { bearer_auth: [] } ]

      response "200", "current user" do
        schema "$ref" => "#/components/schemas/CurrentUser"
        examples "application/json" => {
          id: 1, email: "ada@example.com", unconfirmed_email: nil,
          first_name: "Ada", last_name: "Lovelace",
          username: "ada#0001", role: "player", avatar_url: nil
        }
        let(:user_record) { create(:user) }
        let(:Authorization) { api_auth_headers_for(user_record)["Authorization"] }
        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body).to include("email" => user_record.email, "unconfirmed_email" => nil)
          expect(body).to include("role" => "player")
        end
      end

      response "401", "authentication required" do
        schema "$ref" => "#/components/schemas/Error"
        examples "application/json" => {
          error: { message: "Vous devez vous connecter ou vous inscrire pour continuer." }
        }
        let(:Authorization) { nil }
        run_test! do |response|
          expect(JSON.parse(response.body).dig("error", "message")).to be_present
        end
      end
    end

    patch "Update the current user profile" do
      operationId "updateCurrentUser"
      tags "Users"
      description "Update writable profile fields. Username and role are ignored if sent. " \
                  "Email is reconfirmable: response keeps old email and sets unconfirmed_email. " \
                  "No current_password required. Password change does not revoke JWT. " \
                  "Avatar upload requires multipart/form-data with user[avatar] file (jpg/jpeg/gif/png). " \
                  "Clear avatar with user[remove_avatar]=true. JSON body is for text fields only."
      consumes "application/json", "multipart/form-data"
      produces "application/json"
      security [ { bearer_auth: [] } ]
      parameter name: :profile, in: :body, required: true, schema: {
        type: :object,
        required: [ :user ],
        properties: {
          user: {
            type: :object,
            properties: {
              first_name: { type: :string },
              last_name: { type: :string },
              email: { type: :string, format: :email },
              password: { type: :string, format: :password, minLength: 6, maxLength: 128 },
              password_confirmation: { type: :string, format: :password },
              remove_avatar: {
                type: :boolean,
                description: "When true (multipart or JSON), clears avatar; avatar_url becomes null."
              }
            },
            description: "JSON: text fields only. For avatar file use multipart user[avatar]."
          }
        },
        example: { user: { first_name: "Updated" } }
      }

      response "200", "current user updated" do
        schema "$ref" => "#/components/schemas/CurrentUser"
        examples "application/json" => {
          id: 1, email: "ada@example.com", unconfirmed_email: nil,
          first_name: "Updated", last_name: "Lovelace",
          username: "ada#0001", role: "player", avatar_url: nil
        }
        let(:user_record) { create(:user) }
        let(:Authorization) { api_auth_headers_for(user_record)["Authorization"] }
        let(:profile) { { user: { first_name: "Updated" } } }
        run_test! { expect(user_record.reload.first_name).to eq("Updated") }
      end

      response "401", "authentication required" do
        schema "$ref" => "#/components/schemas/Error"
        let(:Authorization) { nil }
        let(:profile) { { user: { first_name: "Updated" } } }
        run_test!
      end

      response "422", "profile validation failed" do
        schema "$ref" => "#/components/schemas/Error"
        examples "application/json" => {
          error: {
            message: "Validation failed",
            details: { email: [ "L'adresse email n'est pas valide." ] }
          }
        }
        let(:user_record) { create(:user) }
        let(:Authorization) { api_auth_headers_for(user_record)["Authorization"] }
        let(:profile) { { user: { email: "not-an-email" } } }
        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.dig("error", "message")).to eq("Validation failed")
          expect(body.dig("error", "details", "email")).to be_present
        end
      end
    end
  end
end
