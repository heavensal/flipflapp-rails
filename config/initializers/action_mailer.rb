# frozen_string_literal: true

# Devise (and any mailer) may enqueue during an open AR transaction (e.g. signup).
# Defer enqueue until commit so Solid Queue never races an uncommitted User.
Rails.application.config.to_prepare do
  ActionMailer::MailDeliveryJob.enqueue_after_transaction_commit = true
end
