# frozen_string_literal: true

module NotificationsHelper
  KIND_ICON_CLASSES = {
    "updated" => "bg-accent-soft text-title-yellow",
    "canceled" => "bg-danger/20 text-danger",
    "joined" => "bg-success/20 text-success",
    "left" => "bg-surface text-muted",
    "invited" => "bg-accent-soft text-accent",
    "reminder" => "bg-team-a/30 text-secondary-text",
    "friendship_requested" => "bg-accent-soft text-title-yellow"
  }.freeze

  KIND_ROW_CLASSES = {
    "updated" => ->(read) { read ? "bg-accent/20 border-border" : "bg-accent/35 border-accent/40" },
    "canceled" => ->(read) { read ? "bg-danger/15 border-border" : "bg-danger/30 border-danger/40" },
    "joined" => ->(read) { read ? "bg-success/10 border-border" : "bg-success/25 border-success/40" },
    "left" => ->(read) { read ? "bg-surface border-border" : "bg-surface-hover border-border" },
    "invited" => ->(read) { read ? "bg-accent/15 border-border" : "bg-accent/30 border-accent/40" },
    "reminder" => ->(read) { read ? "bg-team-a/15 border-border" : "bg-team-a/30 border-team-a/40" },
    "friendship_requested" => ->(read) { read ? "bg-accent/15 border-border" : "bg-accent/30 border-accent/40" }
  }.freeze

  def notification_message(notification)
    notification.message
  end

  def notification_icon(kind)
    {
      "updated" => "✏️",
      "canceled" => "❌",
      "joined" => "👤",
      "left" => "🚪",
      "invited" => "📨",
      "reminder" => "⏰",
      "friendship_requested" => "🤝"
    }.fetch(kind, "🔔")
  end

  def notification_icon_classes(kind)
    KIND_ICON_CLASSES.fetch(kind, "bg-surface text-muted")
  end

  def notification_row_classes(notification)
    KIND_ROW_CLASSES.fetch(notification.kind, ->(_) { "bg-surface border-border" }).call(notification.read?)
  end
end
