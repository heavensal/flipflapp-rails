# frozen_string_literal: true

class Notifications::MobilePushJob < ApplicationJob
  queue_as :default

  discard_on ActiveJob::DeserializationError

  def perform(notification_id)
    return unless Flipflapp::FcmConfig.configured?

    notification = Notification.find_by(id: notification_id)
    return unless notification

    title = I18n.t("notifications.live_toast.title")
    body = notification.message
    data = {
      notification_id: notification.id,
      kind: notification.kind,
      path: notification.push_path
    }

    client = Flipflapp::FcmClient.new
    notification.user.device_tokens.find_each do |device_token|
      deliver_to(client, device_token, title: title, body: body, data: data)
    end
  end

  private

  def deliver_to(client, device_token, title:, body:, data:)
    client.send_message(
      token: device_token.token,
      title: title,
      body: body,
      data: data
    )
  rescue Flipflapp::FcmClient::Error => error
    if error.unregistered?
      destroy_unregistered_token(device_token)
    else
      Rails.logger.warn(
        "[FCM] delivery failed device_token=#{device_token.id} " \
        "status=#{error.status} code=#{error.error_code}: #{error.message}"
      )
    end
  end

  def destroy_unregistered_token(device_token)
    DeviceToken.find_by(id: device_token.id, user_id: device_token.user_id)&.destroy
  end
end
