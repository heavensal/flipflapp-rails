# frozen_string_literal: true

class AddBenchReminderJobIdToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :bench_reminder_job_id, :string
  end
end
