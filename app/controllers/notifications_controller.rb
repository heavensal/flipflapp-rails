class NotificationsController < ApplicationController
  before_action :authenticate_user!
  def list
  end

  def index
    @notifications = current_user.notifications.recent
  end

  def read
    notification = current_user.notifications.find(params[:id])
    notification.mark_as_read!

    redirect_to notification.target_url || notifications_list_path
  end
end
