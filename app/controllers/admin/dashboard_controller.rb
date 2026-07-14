module Admin
  class DashboardController < BaseController
    def index
      @resources = Admin::Resource.all
    end
  end
end
