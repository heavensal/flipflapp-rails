module EventNotifications
  extend ActiveSupport::Concern

  TRACKED_NOTIFICATION_FIELDS = %w[title start_time price number_of_participants].freeze

  included do
    after_update_commit :notify_update
    before_destroy :prepare_cancellation_notifications, prepend: true
    after_destroy_commit :notify_cancellation
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

    Array(@cancellation_notification_user_ids).each do |player_id|
      Notification.create!(
        user_id: player_id,
        notifiable: nil,
        kind: :canceled,
        payload: @cancellation_notification_payload
      )
    end
  end

  def notify_update
    tracked_changes = saved_changes.slice(*TRACKED_NOTIFICATION_FIELDS)
    return if tracked_changes.empty?

    players.where.not(id: user_id).find_each do |player|
      tracked_changes.each do |field, (old_value, new_value)|
        Notification.create!(
          user: player,
          notifiable: self,
          kind: :updated,
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
