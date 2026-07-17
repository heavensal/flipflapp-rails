# frozen_string_literal: true

module Friendship::Notifications
  extend ActiveSupport::Concern

  included do
    after_create_commit :notify_friendship_requested, if: :pending?
    after_update_commit :cleanup_friendship_notification_after_update
    after_destroy_commit :cleanup_friendship_notification
  end

  private

  def pending?
    status == "pending"
  end

  def notify_friendship_requested
    Notification.deliver_one!(
      user: receiver,
      kind: :friendship_requested,
      notifiable: self,
      payload: { first_name: sender.first_name }
    )
  end

  def cleanup_friendship_notification_after_update
    return unless previous_changes.key?("status")
    return if pending?

    cleanup_friendship_notification
  end

  def cleanup_friendship_notification
    Notification.where(notifiable_type: "Friendship", notifiable_id: id, kind: :friendship_requested).delete_all
  end
end
