# frozen_string_literal: true

class Events::BenchReminderJob < ApplicationJob
  queue_as :default

  discard_on ActiveJob::DeserializationError

  def perform(event_id:, expected_start_time:)
    event = Event.find_by(id: event_id)
    return if event.nil?
    return if event.start_time.iso8601 != expected_start_time

    event.notify_bench_reminder!
  end
end
