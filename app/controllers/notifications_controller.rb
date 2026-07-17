# frozen_string_literal: true

class NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_notification, only: %i[read destroy]

  def list
  end

  def index
    @notifications = current_user.notifications.inbox.recent
  end

  def read
    @notification.mark_as_read!

    if params[:navigate].present? && @notification.clickable?
      redirect_to @notification.target_url
    else
      redirect_to notifications_path
    end
  end

  def read_all
    Notification.mark_all_as_read_for!(current_user)
    redirect_to notifications_path
  end


  def destroy
    @notification.destroy!
    redirect_to notifications_path
  end

  private

  def set_notification
    @notification = current_user.notifications.inbox.find(params[:id])
  end
end
