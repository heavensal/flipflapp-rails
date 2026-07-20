module Admin
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin!

    helper AdminHelper

    private

    def require_admin!
      return if current_user.admin?

      redirect_to authenticated_root_path, alert: t("admin.flash.authorization.forbidden")
    end
  end
end
