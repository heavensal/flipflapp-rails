# frozen_string_literal: true

module Event::Notifications
  extend ActiveSupport::Concern

  TRACKED_NOTIFICATION_FIELDS = %w[title start_time price number_of_participants].freeze

  included do
    after_update_commit :notify_update
    before_destroy :prepare_cancellation_notifications, prepend: true
    after_destroy_commit :notify_cancellation
  end

  def invite!(users:, sender:)
    friends = users.is_a?(ActiveRecord::Relation) ? users.to_a : Array(users)

    Notification.transaction do
      friends.each do |friend|
        Notification.deliver_one!(
          user: friend,
          kind: :invited,
          notifiable: self,
          payload: {
            title: title,
            start_time: start_time,
            sender: sender.first_name
          }
        )
      end
    end
  end

  def prepare_cancellation_notifications
    @cancellation_notification_user_ids = event_participants.where.not(user_id: user_id).distinct.pluck(:user_id)
    @cancellation_notification_payload = {
      title: title,
      start_time: start_time,
      author: user.first_name
    }
  end

  def notify_cancellation
    Notification.where(notifiable_type: self.class.name, notifiable_id: id).delete_all

    Notification.deliver_many!(
      user_ids: @cancellation_notification_user_ids,
      kind: :canceled,
      notifiable: nil,
      payload: @cancellation_notification_payload
    )
  end

  def notify_update
    tracked_changes = saved_changes.slice(*TRACKED_NOTIFICATION_FIELDS)
    return if tracked_changes.empty?

    players.where.not(id: user_id).find_each do |player|
      tracked_changes.each do |field, (old_value, new_value)|
        Notification.deliver_one!(
          user: player,
          kind: :updated,
          notifiable: self,
          payload: update_notification_payload(field, old_value, new_value)
        )
      end
    end
  end

  private

  def update_notification_payload(field, old_value, new_value)
    {
      actor: user.first_name,
      field: field,
      title: field == "title" ? old_value : title,
      start_time: start_time,
      old_value: notification_payload_value(field, old_value),
      new_value: notification_payload_value(field, new_value)
    }
  end

  def notification_payload_value(field, value)
    case field
    when "price" then format("%.2f", value.to_f)
    when "start_time" then value&.iso8601
    else value
    end
  end
end
