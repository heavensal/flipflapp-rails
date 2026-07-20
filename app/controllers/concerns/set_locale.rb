# frozen_string_literal: true

module SetLocale
  extend ActiveSupport::Concern

  COOKIE_NAME = :locale
  COOKIE_EXPIRY = 1.year

  included do
    around_action :switch_locale
  end

  private

  def switch_locale(&action)
    locale = resolve_locale
    I18n.with_locale(locale, &action)
  end

  def resolve_locale
    from_cookie || from_accept_language || I18n.default_locale
  end

  def from_cookie
    locale = cookies[COOKIE_NAME]&.to_sym
    locale if available_locale?(locale)
  end

  def from_accept_language
    return if request.env["HTTP_ACCEPT_LANGUAGE"].blank?

    browser_locales = request.env["HTTP_ACCEPT_LANGUAGE"]
      .split(",")
      .map { |lang| lang.split(";").first.to_s.strip[0, 2].downcase.to_sym }

    browser_locales.find { |locale| available_locale?(locale) }
  end

  def available_locale?(locale)
    locale.present? && I18n.available_locales.include?(locale)
  end

  def persist_locale!(locale)
    locale = locale.to_sym
    return false unless available_locale?(locale)

    cookies[COOKIE_NAME] = {
      value: locale.to_s,
      expires: COOKIE_EXPIRY.from_now,
      same_site: :lax
    }
    true
  end
end
