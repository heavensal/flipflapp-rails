# frozen_string_literal: true

class LocalesController < ApplicationController
  def update
    locale = params[:locale]

    if persist_locale!(locale)
      redirect_back fallback_location: authenticated_root_or_home,
                    notice: I18n.t("layouts.locale.flash.updated", locale: locale)
    else
      redirect_back fallback_location: authenticated_root_or_home,
                    alert: t("layouts.locale.flash.invalid")
    end
  end

  private

  def authenticated_root_or_home
    user_signed_in? ? authenticated_root_path : unauthenticated_root_path
  end
end
