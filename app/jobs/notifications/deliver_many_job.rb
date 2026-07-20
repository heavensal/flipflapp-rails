# frozen_string_literal: true

class Notifications::DeliverManyJob < ApplicationJob
  queue_as :default

  discard_on ActiveJob::DeserializationError

  def perform(user_ids:, kind:, notifiable_gid:, payload:)
    ids = Array(user_ids).uniq
    return if ids.empty?

    notifiable = resolve_notifiable(notifiable_gid)
    return if notifiable_gid.present? && notifiable.nil?

    now = Time.current
    kind_value = Notification.kinds.fetch(kind.to_s)

    result = Notification.insert_all(
      ids.map do |user_id|
        {
          user_id: user_id,
          notifiable_type: notifiable&.class&.name,
          notifiable_id: notifiable&.id,
          kind: kind_value,
          payload: payload,
          read: false,
          created_at: now,
          updated_at: now
        }
      end,
      returning: %w[id]
    )

    Notification.where(id: result.rows.flatten).find_each(&:broadcast_live!)
  end

  private

  def resolve_notifiable(gid)
    return if gid.blank?

    GlobalID::Locator.locate(gid)
  rescue ActiveRecord::RecordNotFound
    nil
  end
end
