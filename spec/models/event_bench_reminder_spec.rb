# frozen_string_literal: true

require "rails_helper"

RSpec.describe Event, "bench reminder", type: :model do
  include ActiveSupport::Testing::TimeHelpers

  def team_slot(event, slot)
    event.event_teams.find_by!(slot: slot)
  end

  describe "#spots_remaining" do
    it "returns open countable slots" do
      event = create(:event, number_of_participants: 4)
      create(:event_participant, user: create(:user), event: event, event_team: team_slot(event, "team_two"))

      expect(event.spots_remaining).to eq(2)
    end
  end

  describe "scheduling" do
    it "enqueues a bench reminder job 24h before start_time on create" do
      freeze_time do
        start_time = 3.days.from_now

        expect {
          create(:event, start_time: start_time)
        }.to have_enqueued_job(Events::BenchReminderJob)
          .with(hash_including(expected_start_time: start_time.iso8601))
          .at(start_time - 24.hours)
      end
    end

    it "enqueues immediately when start_time is less than 24h away" do
      freeze_time do
        start_time = 12.hours.from_now

        expect {
          create(:event, start_time: start_time)
        }.to have_enqueued_job(Events::BenchReminderJob).at(Time.current)
      end
    end

    it "discards the previous job and reschedules when start_time changes" do
      freeze_time do
        event = create(:event, start_time: 3.days.from_now)
        old_job_id = event.reload.bench_reminder_job_id
        new_start = 5.days.from_now

        expect {
          event.update!(start_time: new_start)
        }.to have_enqueued_job(Events::BenchReminderJob)
          .with(hash_including(expected_start_time: new_start.iso8601))
          .at(new_start - 24.hours)

        expect(event.reload.bench_reminder_job_id).to be_present
        expect(event.bench_reminder_job_id).not_to eq(old_job_id)
        expect(enqueued_jobs.count { |job| job["job_id"] == old_job_id }).to eq(0)
      end
    end

    it "discards the pending reminder job when the event is destroyed" do
      event = create(:event, start_time: 3.days.from_now)
      job_id = event.reload.bench_reminder_job_id

      event.destroy!

      expect(enqueued_jobs.count { |job| job["job_id"] == job_id }).to eq(0)
    end
  end

  describe "#notify_bench_reminder!", :notification_jobs do
    it "delivers a reminder to every bench user when spots remain" do
      event = create(:event, number_of_participants: 4, start_time: 2.days.from_now)
      bench_a = create(:user)
      bench_b = create(:user)
      create(:event_participant, user: bench_a, event: event, event_team: team_slot(event, "bench"))
      create(:event_participant, user: bench_b, event: event, event_team: team_slot(event, "bench"))

      expect {
        event.notify_bench_reminder!
      }.to change { bench_a.notifications.reminder.count }.by(1)
        .and change { bench_b.notifications.reminder.count }.by(1)

      notification = bench_a.notifications.reminder.last
      expect(notification.notifiable).to eq(event)
      expect(notification.payload).to include(
        "title" => event.title,
        "author" => event.user.first_name,
        "spots_remaining" => event.spots_remaining
      )
      expect(notification.payload["start_time"]).to eq(event.start_time.iso8601)
    end

    it "sends nothing when countable slots are full" do
      event = create(:event, number_of_participants: 2, start_time: 2.days.from_now)
      create(:event_participant, user: create(:user), event: event, event_team: team_slot(event, "team_two"))
      bench_player = create(:user)
      create(:event_participant, user: bench_player, event: event, event_team: team_slot(event, "bench"))

      expect {
        event.notify_bench_reminder!
      }.not_to change { Notification.where(kind: :reminder).count }
    end

    it "sends nothing when the bench is empty" do
      event = create(:event, number_of_participants: 4, start_time: 2.days.from_now)

      expect {
        event.notify_bench_reminder!
      }.not_to change { Notification.where(kind: :reminder).count }
    end

    it "is idempotent for the same start_time" do
      event = create(:event, number_of_participants: 4, start_time: 2.days.from_now)
      bench_player = create(:user)
      create(:event_participant, user: bench_player, event: event, event_team: team_slot(event, "bench"))

      event.notify_bench_reminder!

      expect {
        event.notify_bench_reminder!
      }.not_to change { bench_player.notifications.reminder.count }
    end

    it "sends again after start_time changes" do
      event = create(:event, number_of_participants: 4, start_time: 2.days.from_now)
      bench_player = create(:user)
      create(:event_participant, user: bench_player, event: event, event_team: team_slot(event, "bench"))
      event.notify_bench_reminder!

      # Skip reschedule callbacks so :notification_jobs does not auto-run the new delayed job.
      event.update_columns(start_time: 4.days.from_now)

      expect {
        event.notify_bench_reminder!
      }.to change { bench_player.notifications.reminder.count }.by(1)
    end
  end

  describe Events::BenchReminderJob do
    it "no-ops when expected_start_time is stale" do
      event = create(:event, start_time: 3.days.from_now)
      create(:event_participant, user: create(:user), event: event, event_team: team_slot(event, "bench"))
      stale = event.start_time.iso8601
      event.update!(start_time: 5.days.from_now)

      expect {
        described_class.perform_now(event_id: event.id, expected_start_time: stale)
      }.not_to change { Notification.where(kind: :reminder).count }
    end

    it "no-ops when the event was destroyed" do
      expect {
        described_class.perform_now(event_id: 0, expected_start_time: 1.day.from_now.iso8601)
      }.not_to change { Notification.where(kind: :reminder).count }
    end
  end
end
