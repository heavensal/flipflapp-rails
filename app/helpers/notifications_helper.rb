module NotificationsHelper
  def notification_message(notification)
    case notification.kind
    when "joined"
      t("notifications.messages.joined", player: notification.payload["player"], title: notification.payload["title"])
    when "left"
      t("notifications.messages.left", player: notification.payload["player"], title: notification.payload["title"])
    when "updated"
      notification_update_message(notification)
    when "invited"
      t(
        "notifications.messages.invited",
        sender: notification.payload["sender"],
        title: notification.payload["title"],
        start_time: human_future_date(notification.payload["start_time"])
      )
    when "canceled"
      t(
        "notifications.messages.canceled",
        title: notification.payload["title"],
        start_time: human_future_date(notification.payload["start_time"]),
        author: notification.payload["author"]
      )
    else
      t("notifications.messages.default")
    end
  end

  def notification_icon(kind)
    case kind
    when "created" then "🆕"
    when "updated" then "✏️"
    when "canceled" then "❌"
    when "joined" then "👤"
    when "left" then "🚪"
    when "invited" then "📨"
    when "reminder" then "⏰"
    else "🔔"
    end
  end

  def notification_update_message(notification)
    field = notification.payload["field"]
    translation_key = "notifications.messages.updated.#{field}"
    translation_key = "notifications.messages.updated.default" unless I18n.exists?(translation_key)

    t(
      translation_key,
      actor: notification.payload["actor"],
      title: notification.payload["title"],
      field: field.to_s.humanize,
      value: notification_updated_value(field, notification.payload["new_value"])
    )
  end

  def notification_updated_value(field, value)
    case field
    when "start_time"
      human_future_date(value)
    when "price"
      "#{format('%.2f', value.to_f)} €"
    else
      value
    end
  end
end
