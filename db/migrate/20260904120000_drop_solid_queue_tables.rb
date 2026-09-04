# frozen_string_literal: true

# Jobs move to Sidekiq + Redis. Keep DDL out of the same transaction as
# Active Job / Redis writes so an enqueue failure cannot abort db:prepare.
class DropSolidQueueTables < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

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
    reschedule_upcoming_bench_reminders
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def reschedule_upcoming_bench_reminders
    return unless table_exists?(:events)
    return unless column_exists?(:events, :bench_reminder_job_id)

    say_with_time "reschedule upcoming bench reminders onto Sidekiq" do
      Event.reschedule_upcoming_bench_reminders!
    end
  rescue RedisClient::Error, ActiveJob::EnqueueError => error
    say "Skipping bench reminder reschedule (#{error.class})"
  end
end
