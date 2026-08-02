# frozen_string_literal: true

require "json"
require "yaml"
require "fileutils"

module MobileDocsExport
  module_function

  def export!(domain:, companions:)
    root = Rails.root
    source = root.join("swagger/v1/swagger.yaml")
    dest_dir = root.join("docs/mobile/#{domain}")
    FileUtils.mkdir_p(dest_dir)

    abort "Missing #{source}. Run: bundle exec rake rswag:specs:swaggerize" unless source.file?

    require_relative "openapi_users_request_body"
    openapi = YAML.safe_load_file(source, aliases: true)
    OpenapiUsersRequestBody.patch!(openapi)
    File.write(dest_dir.join("openapi.json"), JSON.pretty_generate(openapi) + "\n")
    puts "Wrote #{dest_dir.join('openapi.json')}"

    companions.each do |name|
      path = dest_dir.join(name)
      raise "Missing companion file: #{path}" unless path.exist?

      puts "OK #{path}"
    end
  end
end
