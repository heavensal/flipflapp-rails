# frozen_string_literal: true

module Event::BenchReminder
  extend ActiveSupport::Concern

  included do
    after_create_commit :schedule_bench_reminder!
    after_update_commit :reschedule_bench_reminder_if_start_time_changed
    before_destroy :discard_bench_reminder_job!, prepend: true
  end

  class_methods do
    def reschedule_upcoming_bench_reminders!
      upcoming.except(:order).find_each(&:schedule_bench_reminder!)
    end
  end

  def schedule_bench_reminder!
    discard_bench_reminder_job!

    job = Events::BenchReminderJob
      .set(wait_until: [ reminder_due_at, Time.current ].max)
      .perform_later(event_id: id, expected_start_time: start_time.iso8601)

    update_column(:bench_reminder_job_id, job.job_id)
  end

  def notify_bench_reminder!
    # Clear the stored id only — do not cancel the Sidekiq job that is
    # currently executing this method.
    clear_bench_reminder_job_id!
    return if spots_remaining <= 0

    ids = bench_user_ids
    return if ids.empty?
    return if reminder_already_sent_for_current_start_time?

    Notification.deliver_many!(
      user_ids: ids,
      kind: :reminder,
      notifiable: self,
      payload: {
        title: title,
        author: user.first_name,
        start_time: start_time,
        spots_remaining: spots_remaining
      }
    )
  end

  def discard_bench_reminder_job!
    job_id = bench_reminder_job_id
    return if job_id.blank?

    clear_bench_reminder_job_id!
    discard_active_job(job_id)
  end

  private

  def reschedule_bench_reminder_if_start_time_changed
    return unless saved_change_to_start_time?

    schedule_bench_reminder!
  end

  def clear_bench_reminder_job_id!
    return if bench_reminder_job_id.blank?
    return unless self.class.exists?(id)

    update_column(:bench_reminder_job_id, nil)
  end

  def discard_active_job(job_id)
    adapter = ActiveJob::Base.queue_adapter
    if adapter.respond_to?(:enqueued_jobs)
      adapter.enqueued_jobs.reject! { |job| job["job_id"] == job_id }
    else
      discard_sidekiq_job(job_id)
    end
  end

  def discard_sidekiq_job(job_id)
    require "sidekiq/api"

    [ Sidekiq::ScheduledSet.new, Sidekiq::RetrySet.new ].each do |set|
      set.each { |job| job.delete if sidekiq_active_job_id(job) == job_id }
    end
  rescue RedisClient::Error
    # Redis down — job may still fire; BenchReminderJob no-ops if stale/destroyed.
  end

  def sidekiq_active_job_id(job)
    payload = job.args.first
    payload["job_id"] if payload.is_a?(Hash)
  end

  def reminder_already_sent_for_current_start_time?
    notifications.reminder.where("payload->>'start_time' = ?", start_time.iso8601).exists?
  end
end
