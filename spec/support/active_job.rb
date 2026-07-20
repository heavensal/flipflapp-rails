# frozen_string_literal: true

RSpec.configure do |config|
  config.include ActiveJob::TestHelper

  config.around(:each, :notification_jobs) do |example|
    perform_enqueued_jobs { example.run }
  end
end
