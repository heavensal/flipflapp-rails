# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: ENV["SMTP_USERNAME"]
  layout "mailer"

  # Always use deliver_later (Active Job / Solid Queue). Prefer deliver_now only in console/debug.
end
