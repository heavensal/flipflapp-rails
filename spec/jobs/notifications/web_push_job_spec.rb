# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifications::WebPushJob, type: :job do
  def stub_response(code)
    instance_double(Net::HTTPResponse, code: code.to_s, body: "", inspect: "response #{code}")
  end

  it "no-ops when VAPID is not configured" do
    allow(Flipflapp::WebPushConfig).to receive(:configured?).and_return(false)
    notification = create(:notification)
    create(:push_subscription, user: notification.user)

    expect(WebPush).not_to receive(:payload_send)

    described_class.perform_now(notification.id)
  end

  it "sends a web push payload to each subscription" do
    allow(Flipflapp::WebPushConfig).to receive_messages(
      configured?: true,
      vapid_options: { subject: "mailto:test@example.com", public_key: "pub", private_key: "priv" }
    )

    notification = create(:notification, kind: :invited, payload: { title: "Match", sender: "Ada", start_time: 1.day.from_now.iso8601 })
    subscription = create(:push_subscription, user: notification.user)

    expect(WebPush).to receive(:payload_send).with(hash_including(
      endpoint: subscription.endpoint,
      p256dh: subscription.p256dh,
      auth: subscription.auth,
      message: a_string_including("\"title\"")
    ))

    described_class.perform_now(notification.id)
  end

  it "destroys expired subscriptions" do
    allow(Flipflapp::WebPushConfig).to receive_messages(
      configured?: true,
      vapid_options: { subject: "mailto:test@example.com", public_key: "pub", private_key: "priv" }
    )

    notification = create(:notification)
    subscription = create(:push_subscription, user: notification.user)

    allow(WebPush).to receive(:payload_send).and_raise(
      WebPush::ExpiredSubscription.new(stub_response(410), "fcm.googleapis.com")
    )

    expect {
      described_class.perform_now(notification.id)
    }.to change(PushSubscription, :count).by(-1)

    expect(PushSubscription.exists?(subscription.id)).to be(false)
  end
end
