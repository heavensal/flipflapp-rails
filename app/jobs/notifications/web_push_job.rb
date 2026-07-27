# frozen_string_literal: true

class Notifications::WebPushJob < ApplicationJob
  queue_as :default

  discard_on ActiveJob::DeserializationError

  def perform(notification_id)
    return unless Flipflapp::WebPushConfig.configured?

    notification = Notification.find_by(id: notification_id)
    return unless notification

    payload = {
      title: I18n.t("notifications.live_toast.title"),
      body: notification.message,
      path: notification.push_path
    }

    notification.user.push_subscriptions.find_each do |subscription|
      deliver_to(subscription, payload)
    end
  end

  private

  def deliver_to(subscription, payload)
    subscription.deliver_payload!(payload)
  rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
    subscription.destroy
  rescue WebPush::ResponseError => error
    raise unless [ 404, 410 ].include?(error.response.code.to_i)

    subscription.destroy
  end
end
