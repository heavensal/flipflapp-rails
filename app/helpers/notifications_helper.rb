# frozen_string_literal: true

module NotificationsHelper
  KIND_ICON_CLASSES = {
    "updated" => "bg-orange-100 text-orange-600",
    "canceled" => "bg-red-100 text-red-600",
    "joined" => "text-green-600",
    "left" => "bg-gray-100 text-gray-600",
    "invited" => "bg-indigo-100 text-indigo-600",
    "reminder" => "bg-blue-100 text-blue-600"
  }.freeze

  KIND_ROW_CLASSES = {
    "updated" => ->(read) { read ? "bg-amber-500/50" : "bg-amber-500" },
    "canceled" => ->(read) { read ? "bg-red-900/50" : "bg-red-900" },
    "joined" => ->(read) { read ? "bg-blue-800/30" : "bg-blue-800/70" },
    "left" => ->(read) { read ? "bg-red-900/50" : "bg-red-900" },
    "invited" => ->(read) { read ? "bg-blue-800/30" : "bg-blue-800/70" },
    "reminder" => ->(read) { read ? "bg-blue-800/30" : "bg-blue-800/70" }
  }.freeze

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
    when "reminder"
      t("notifications.messages.reminder", title: notification.payload["title"])
    else
      t("notifications.messages.default")
    end
  end

  def notification_icon(kind)
    {
      "updated" => "✏️",
      "canceled" => "❌",
      "joined" => "👤",
      "left" => "🚪",
      "invited" => "📨",
      "reminder" => "⏰"
    }.fetch(kind, "🔔")
  end

  def notification_icon_classes(kind)
    KIND_ICON_CLASSES.fetch(kind, "bg-gray-100 text-gray-400")
  end

  def notification_row_classes(notification)
    KIND_ROW_CLASSES.fetch(notification.kind, ->(_) { "bg-white/10" }).call(notification.read?)
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
