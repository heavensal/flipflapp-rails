# frozen_string_literal: true

module Event::BenchReminder
  extend ActiveSupport::Concern

  included do
    after_create_commit :schedule_bench_reminder!
    after_update_commit :reschedule_bench_reminder_if_start_time_changed
    before_destroy :discard_bench_reminder_job!, prepend: true
  end

  def schedule_bench_reminder!
    discard_bench_reminder_job!

    job = Events::BenchReminderJob
      .set(wait_until: [ reminder_due_at, Time.current ].max)
      .perform_later(event_id: id, expected_start_time: start_time.iso8601)

    update_column(:bench_reminder_job_id, job.job_id)
  end

  def notify_bench_reminder!
    discard_bench_reminder_job!
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
    if defined?(SolidQueue::Job)
      solid_job = SolidQueue::Job.find_by(active_job_id: job_id)
      return solid_job.discard if solid_job
    end

    adapter = ActiveJob::Base.queue_adapter
    return unless adapter.respond_to?(:enqueued_jobs)

    adapter.enqueued_jobs.reject! { |job| job["job_id"] == job_id }
  end

  def reminder_already_sent_for_current_start_time?
    notifications.reminder.where("payload->>'start_time' = ?", start_time.iso8601).exists?
  end
end
