module EventsHelper
  def human_future_date(date)
    return "" if date.blank?

    today = Date.current
    target = date.to_date

    case target
    when today
      I18n.l(date, format: :today_with_time)
    when today + 1
      I18n.l(date, format: :tomorrow_with_time)
    when today + 2
      I18n.l(date, format: :after_tomorrow_with_time)
    when (today..today + 6)
      I18n.l(date, format: :weekday_with_time) # => "vendredi"
    else
      I18n.l(date, format: :short_with_time)      # => "lundi 16 sept à 18h00"
    end
  end
end
