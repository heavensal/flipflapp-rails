# frozen_string_literal: true

require "rails_helper"

RSpec.describe Flipflapp::FcmConfig do
  around do |example|
    original_project = ENV["FCM_PROJECT_ID"]
    original_json = ENV["FCM_SERVICE_ACCOUNT_JSON"]
    example.run
  ensure
    ENV["FCM_PROJECT_ID"] = original_project
    ENV["FCM_SERVICE_ACCOUNT_JSON"] = original_json
  end

  def account_json(private_key:)
    {
      type: "service_account",
      project_id: "flipflapp-production",
      private_key: private_key,
      client_email: "firebase-adminsdk@flipflapp-production.iam.gserviceaccount.com"
    }.to_json
  end

  describe ".service_account_json" do
    it "rewrites literal \\n sequences in private_key into real newlines" do
      mangled_pem = "-----BEGIN PRIVATE KEY-----\\nMIIEtest\\n-----END PRIVATE KEY-----\\n"
      ENV["FCM_SERVICE_ACCOUNT_JSON"] = account_json(private_key: mangled_pem)

      parsed = JSON.parse(described_class.service_account_json)
      private_key = parsed.fetch("private_key")

      expect(private_key).to include("\n")
      expect(private_key).not_to include("\\n")
      expect(private_key).to start_with("-----BEGIN PRIVATE KEY-----\n")
    end

    it "leaves an already-valid private_key unchanged" do
      valid_pem = "-----BEGIN PRIVATE KEY-----\nMIIEtest\n-----END PRIVATE KEY-----\n"
      ENV["FCM_SERVICE_ACCOUNT_JSON"] = account_json(private_key: valid_pem)

      parsed = JSON.parse(described_class.service_account_json)

      expect(parsed.fetch("private_key")).to eq(valid_pem)
    end

    it "returns the raw value when JSON is invalid" do
      ENV["FCM_SERVICE_ACCOUNT_JSON"] = "not-json"

      expect(described_class.service_account_json).to eq("not-json")
    end
  end

  describe ".configured?" do
    it "is true when project id and service account json are present" do
      ENV["FCM_PROJECT_ID"] = "flipflapp-production"
      ENV["FCM_SERVICE_ACCOUNT_JSON"] = account_json(
        private_key: "-----BEGIN PRIVATE KEY-----\nMIIE\n-----END PRIVATE KEY-----\n"
      )

      expect(described_class.configured?).to be(true)
    end
  end
end
