# frozen_string_literal: true

class PushSubscription < ApplicationRecord
  belongs_to :user

  validates :endpoint, presence: true, uniqueness: true
  validates :p256dh, presence: true
  validates :auth, presence: true

  def self.register_for(user, endpoint:, p256dh:, auth:)
    subscription = find_or_initialize_by(endpoint: endpoint)
    subscription.user = user
    subscription.p256dh = p256dh
    subscription.auth = auth
    subscription
  end

  def deliver_payload!(payload)
    WebPush.payload_send(
      message: JSON.generate(payload),
      endpoint: endpoint,
      p256dh: p256dh,
      auth: auth,
      vapid: Flipflapp::WebPushConfig.vapid_options
    )
  end
end
