# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include SetLocale

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # Note: If Safari on iPhone cannot open the site, you may need to adjust the browser compatibility settings.
  # allow_browser versions: :modern
end
