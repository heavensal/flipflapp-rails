# frozen_string_literal: true

module Notification::Message
  extend ActiveSupport::Concern

  def message
    case kind
    when "joined"
      I18n.t("notifications.messages.joined", player: payload["player"], title: payload["title"])
    when "left"
      I18n.t("notifications.messages.left", player: payload["player"], title: payload["title"])
    when "updated"
      update_message
    when "invited"
      I18n.t(
        "notifications.messages.invited",
        sender: payload["sender"],
        title: payload["title"],
        start_time: format_message_date(payload["start_time"])
      )
    when "canceled"
      I18n.t(
        "notifications.messages.canceled",
        title: payload["title"],
        start_time: format_message_date(payload["start_time"]),
        author: payload["author"]
      )
    when "reminder"
      I18n.t(
        "notifications.messages.reminder",
        count: payload["spots_remaining"].to_i,
        title: payload["title"],
        author: payload["author"],
        start_time: format_message_date(payload["start_time"])
      )
    when "friendship_requested"
      I18n.t("notifications.messages.friendship_requested", first_name: payload["first_name"])
    else
      I18n.t("notifications.messages.default")
    end
  end

  def push_path
    target_url.presence || Rails.application.routes.url_helpers.notifications_list_path
  end

  private

  def update_message
    field = payload["field"]
    key = "notifications.messages.updated.#{field}"
    key = "notifications.messages.updated.default" unless I18n.exists?(key)

    I18n.t(
      key,
      actor: payload["actor"],
      title: payload["title"],
      field: field.to_s.humanize,
      value: format_updated_value(field, payload["new_value"])
    )
  end

  def format_updated_value(field, value)
    case field
    when "start_time" then format_message_date(value)
    when "price" then "#{format('%.2f', value.to_f)} €"
    else value
    end
  end

  def format_message_date(date)
    return "" if date.blank?

    parsed =
      case date
      when String then Time.zone.parse(date)
      when Integer then Time.zone.at(date)
      else date
      end

    today = Date.current
    target = parsed.to_date
    format =
      case target
      when today then :today_with_time
      when today + 1 then :tomorrow_with_time
      when today + 2 then :after_tomorrow_with_time
      when (today..today + 6) then :weekday_with_time
      else :short_with_time
      end

    I18n.l(parsed, format: format)
  end
end
