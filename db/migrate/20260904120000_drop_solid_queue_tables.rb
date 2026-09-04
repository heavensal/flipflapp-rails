# frozen_string_literal: true

# Jobs move to Sidekiq + Redis. Re-enqueue unfinished work before the drop so
# T−24h bench reminders and in-flight mail/notification jobs are not discarded.
class DropSolidQueueTables < ActiveRecord::Migration[8.0]
  TABLES = %i[
    solid_queue_blocked_executions
    solid_queue_claimed_executions
    solid_queue_failed_executions
    solid_queue_pauses
    solid_queue_processes
    solid_queue_ready_executions
    solid_queue_recurring_executions
    solid_queue_recurring_tasks
    solid_queue_scheduled_executions
    solid_queue_semaphores
    solid_queue_jobs
  ].freeze
  BENCH_REMINDER_JOB = "Events::BenchReminderJob"

  def up
    reenqueue_unfinished_jobs
    reschedule_upcoming_bench_reminders
    TABLES.each { |table| drop_table table, if_exists: true, force: :cascade }
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def reschedule_upcoming_bench_reminders
    return unless table_exists?(:events)

    say_with_time "reschedule upcoming bench reminders onto Sidekiq" do
      Event.reset_column_information
      Event.reschedule_upcoming_bench_reminders!
    end
  end

  def reenqueue_unfinished_jobs
    return unless table_exists?(:solid_queue_jobs)

    say_with_time "re-enqueue unfinished Solid Queue jobs onto Sidekiq" do
      unfinished_solid_queue_jobs.each do |row|
        next if row["class_name"] == BENCH_REMINDER_JOB
        next if row["arguments"].blank?

        reenqueue_solid_queue_job(row)
      end
    end
  end

  def unfinished_solid_queue_jobs
    select_all(<<~SQL.squish)
      SELECT j.class_name, j.arguments, j.scheduled_at
      FROM solid_queue_jobs j
      WHERE j.finished_at IS NULL
        AND NOT EXISTS (
          SELECT 1 FROM solid_queue_failed_executions f WHERE f.job_id = j.id
        )
        AND NOT EXISTS (
          SELECT 1 FROM solid_queue_claimed_executions c WHERE c.job_id = j.id
        )
    SQL
  end

  def reenqueue_solid_queue_job(row)
    job_data = row["arguments"]
    job_data = JSON.parse(job_data) if job_data.is_a?(String)
    job = ActiveJob::Base.deserialize(job_data)
    scheduled_at = parse_solid_queue_time(row["scheduled_at"])
    if scheduled_at && scheduled_at > Time.current
      job.enqueue(wait_until: scheduled_at)
    else
      job.enqueue
    end
  end

  def parse_solid_queue_time(value)
    return if value.blank?
    return value if value.is_a?(Time)

    Time.zone.parse(value.to_s)
  end
end
