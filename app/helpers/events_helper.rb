module EventsHelper
  FILL_LEVEL_CLASSES = {
    open: "text-green-500",
    tight: "text-primary-yellow",
    full: "text-red-500"
  }.freeze

  SHOW_FILL_LEVEL_CLASSES = {
    open: "text-green-400 font-bold",
    tight: "text-yellow-400 font-bold",
    full: "text-red-500 font-bold"
  }.freeze

  FILL_ARIA_KEYS = {
    open: "available",
    tight: "almost_full",
    full: "full"
  }.freeze

  def human_future_date(date)
    return "" if date.blank?

    date = normalize_future_date(date)
    today = Date.current
    target = date.to_date

    format =
      case target
      when today then :today_with_time
      when today + 1 then :tomorrow_with_time
      when today + 2 then :after_tomorrow_with_time
      when (today..today + 6) then :weekday_with_time
      else :short_with_time
      end

    I18n.l(date, format: format)
  end

  def event_fill_badge(event, context: :card)
    level = event.fill_level
    classes = context == :show ? SHOW_FILL_LEVEL_CLASSES : FILL_LEVEL_CLASSES
    label = level == :full ? t("events.show.full") : "#{event.participants_count} / #{event.number_of_participants}"

    content_tag(
      :span,
      label,
      class: classes.fetch(level),
      aria: { label: t("events.show.aria.#{FILL_ARIA_KEYS.fetch(level)}") }
    )
  end

  def format_event_price(price)
    number_to_currency(
      price,
      unit: "€",
      separator: ",",
      delimiter: " ",
      format: "%n %u",
      precision: 2
    )
  end

  private

  def normalize_future_date(date)
    case date
    when String then Time.zone.parse(date)
    when Integer then Time.zone.at(date)
    else date
    end
  end
end
