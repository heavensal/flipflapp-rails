# frozen_string_literal: true

module Api
  module V1
    class NotificationsController < BaseController
      before_action :set_notification, only: %i[read destroy]

      def index
        notifications = current_user.notifications.inbox.recent
        render json: NotificationSerializer.new(notifications).serializable_hash
      end

      def read
        @notification.mark_as_read!
        render json: NotificationSerializer.new(@notification).serializable_hash
      end

      def read_all
        Notification.mark_all_as_read_for!(current_user)
        head :no_content
      end

      def destroy
        @notification.destroy!
        head :no_content
      end

      private

      def set_notification
        @notification = current_user.notifications.inbox.find(params[:id])
      end
    end
  end
end
