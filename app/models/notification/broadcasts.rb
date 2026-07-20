# frozen_string_literal: true

module Notification::Broadcasts
  extend ActiveSupport::Concern

  def broadcast_live!
    broadcast_append_to(
      user,
      target: "notification_toasts",
      partial: "notifications/components/live_toast",
      locals: { notification: self }
    )
    broadcast_replace_to(
      user,
      target: "notifications_unread_badge",
      partial: "notifications/components/unread_badge",
      locals: { count: user.notifications.inbox.unread.count }
    )
  end
end
