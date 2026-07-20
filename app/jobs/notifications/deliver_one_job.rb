# frozen_string_literal: true

class Notifications::DeliverOneJob < ApplicationJob
  queue_as :default

  discard_on ActiveJob::DeserializationError

  def perform(user_id:, kind:, notifiable_gid:, payload:)
    user = User.find_by(id: user_id)
    return unless user

    notifiable = resolve_notifiable(notifiable_gid)
    return if notifiable_gid.present? && notifiable.nil?
    return if stale_friendship_request?(kind, notifiable)

    notification = Notification.create!(
      user: user,
      kind: kind,
      notifiable: notifiable,
      payload: payload,
      read: false
    )
    notification.broadcast_live!
  end

  private

  def resolve_notifiable(gid)
    return if gid.blank?

    GlobalID::Locator.locate(gid)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def stale_friendship_request?(kind, notifiable)
    kind.to_s == "friendship_requested" &&
      !(notifiable.is_a?(Friendship) && notifiable.status == "pending")
  end
end
