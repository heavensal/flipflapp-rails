# frozen_string_literal: true

require "json"
require "yaml"
require "fileutils"

namespace :mobile do
  desc "Export Auth OpenAPI + companion docs to docs/mobile/auth/"
  task export_auth_docs: :environment do
    root = Rails.root
    source = root.join("swagger/v1/swagger.yaml")
    dest_dir = root.join("docs/mobile/auth")
    FileUtils.mkdir_p(dest_dir)

    openapi = YAML.safe_load_file(source, aliases: true)
    File.write(dest_dir.join("openapi.json"), JSON.pretty_generate(openapi))

    puts "Wrote #{dest_dir.join('openapi.json')}"
    %w[errors.json flows.json client.json].each do |name|
      path = dest_dir.join(name)
      raise "Missing companion file: #{path}" unless path.exist?

      puts "OK #{path}"
    end
  end
end
