# frozen_string_literal: true

namespace :openapi do
  desc "Export swagger/v1/swagger.yaml to JSON handoff paths (swagger/v1 + docs/api/v1)"
  task export: :environment do
    require "yaml"
    require "json"

    yaml_path = Rails.root.join("swagger/v1/swagger.yaml")
    abort "Missing #{yaml_path}. Run: bundle exec rake rswag:specs:swaggerize" unless yaml_path.file?

    document = YAML.safe_load(
      yaml_path.read,
      permitted_classes: [ Date, Time, DateTime ],
      aliases: true
    )
    payload = JSON.pretty_generate(document) + "\n"

    json_paths = [
      Rails.root.join("swagger/v1/openapi.json"),
      Rails.root.join("docs/api/v1/openapi.json")
    ]

    json_paths.each do |json_path|
      json_path.dirname.mkpath
      json_path.write(payload)
      puts "Wrote #{json_path}"
    end
  end
end
