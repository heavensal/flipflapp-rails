# frozen_string_literal: true

require_relative "../mobile_docs_export"

namespace :mobile do
  companions = %w[errors.json flows.json client.json CLIENT_CONTRACT.md].freeze

  desc "Export Auth OpenAPI + companion docs to docs/mobile/auth/"
  task export_auth_docs: :environment do
    MobileDocsExport.export!(
      domain: "auth",
      companions: %w[errors.json flows.json client.json]
    )
  end

  desc "Export Users OpenAPI + companion docs to docs/mobile/users/"
  task export_users_docs: :environment do
    MobileDocsExport.export!(domain: "users", companions: companions)
  end

  desc "Export Events OpenAPI + companion docs to docs/mobile/events/"
  task export_events_docs: :environment do
    MobileDocsExport.export!(domain: "events", companions: companions)
  end

  desc "Export Notifications OpenAPI + companion docs to docs/mobile/notifications/"
  task export_notifications_docs: :environment do
    MobileDocsExport.export!(domain: "notifications", companions: companions)
  end

  desc "Export DeviceTokens OpenAPI + companion docs to docs/mobile/device_tokens/"
  task export_device_tokens_docs: :environment do
    MobileDocsExport.export!(domain: "device_tokens", companions: companions)
  end
end
