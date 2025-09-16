class NotificationsController < ApplicationController
  before_action :authenticate_user!
  def list
  end

  def index
    @notifications = current_user.notifications.recent
  end
end
