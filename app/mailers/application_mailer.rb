# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV["SMTP_USERNAME"].presence || "noreply@flipflapp.fr" }
  layout "mailer"
  before_action :attach_brand_images

  # Always use deliver_later (Active Job / Solid Queue). Prefer deliver_now only in console/debug.

  private

  def attach_brand_images
    attachments.inline["flipflapp_email.jpg"] = Rails.root.join("public/mailer/flipflapp_email.jpg").binread
    attachments.inline["flipflapp_logo.png"] = Rails.root.join("public/mailer/flipflapp_logo.png").binread
  end
end
