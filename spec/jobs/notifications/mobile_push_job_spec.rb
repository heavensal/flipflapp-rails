# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifications::MobilePushJob, type: :job do
  it "no-ops when FCM is not configured" do
    allow(Flipflapp::FcmConfig).to receive(:configured?).and_return(false)
    notification = create(:notification)
    create(:device_token, user: notification.user)

    expect(Flipflapp::FcmClient).not_to receive(:new)

    described_class.perform_now(notification.id)
  end

  it "sends an FCM payload to each device token" do
    allow(Flipflapp::FcmConfig).to receive(:configured?).and_return(true)

    notification = create(
      :notification,
      kind: :invited,
      payload: { title: "Match", sender: "Ada", start_time: 1.day.from_now.iso8601 }
    )
    device_token = create(:device_token, user: notification.user)
    client = instance_double(Flipflapp::FcmClient)

    expect(Flipflapp::FcmClient).to receive(:new).and_return(client)
    expect(client).to receive(:send_message).with(
      token: device_token.token,
      title: I18n.t("notifications.live_toast.title"),
      body: notification.message,
      data: hash_including(
        notification_id: notification.id,
        kind: "invited",
        path: notification.push_path
      )
    )

    described_class.perform_now(notification.id)
  end

  it "destroys unregistered device tokens" do
    allow(Flipflapp::FcmConfig).to receive(:configured?).and_return(true)

    notification = create(:notification)
    device_token = create(:device_token, user: notification.user)
    client = instance_double(Flipflapp::FcmClient)

    allow(Flipflapp::FcmClient).to receive(:new).and_return(client)
    allow(client).to receive(:send_message).and_raise(
      Flipflapp::FcmClient::Error.new("Requested entity was not found.", status: 404, error_code: "UNREGISTERED")
    )

    expect {
      described_class.perform_now(notification.id)
    }.to change(DeviceToken, :count).by(-1)

    expect(DeviceToken.exists?(device_token.id)).to be(false)
  end

  it "does not destroy tokens on INVALID_ARGUMENT payload errors" do
    allow(Flipflapp::FcmConfig).to receive(:configured?).and_return(true)

    notification = create(:notification)
    device_token = create(:device_token, user: notification.user)
    client = instance_double(Flipflapp::FcmClient)

    allow(Flipflapp::FcmClient).to receive(:new).and_return(client)
    allow(client).to receive(:send_message).and_raise(
      Flipflapp::FcmClient::Error.new("Invalid data key", status: 400, error_code: "INVALID_ARGUMENT")
    )

    expect { described_class.perform_now(notification.id) }.not_to change(DeviceToken, :count)
    expect(DeviceToken.exists?(device_token.id)).to be(true)
  end

  it "does not destroy a token reassigned to another user" do
    allow(Flipflapp::FcmConfig).to receive(:configured?).and_return(true)

    notification = create(:notification)
    device_token = create(:device_token, user: notification.user)
    other_user = create(:user)
    client = instance_double(Flipflapp::FcmClient)

    allow(Flipflapp::FcmClient).to receive(:new).and_return(client)
    allow(client).to receive(:send_message) do
      device_token.update!(user: other_user)
      raise Flipflapp::FcmClient::Error.new(
        "Requested entity was not found.",
        status: 404,
        error_code: "UNREGISTERED"
      )
    end

    expect { described_class.perform_now(notification.id) }.not_to change(DeviceToken, :count)
    expect(device_token.reload.user_id).to eq(other_user.id)
  end

  it "continues delivering after a non-unregistered error" do
    allow(Flipflapp::FcmConfig).to receive(:configured?).and_return(true)

    notification = create(:notification)
    first = create(:device_token, user: notification.user)
    second = create(:device_token, user: notification.user)
    client = instance_double(Flipflapp::FcmClient)
    call_count = 0

    allow(Flipflapp::FcmClient).to receive(:new).and_return(client)
    allow(client).to receive(:send_message) do |token:, **|
      call_count += 1
      if token == first.token
        raise Flipflapp::FcmClient::Error.new("Unavailable", status: 500, error_code: "UNAVAILABLE")
      end
    end

    expect { described_class.perform_now(notification.id) }.not_to raise_error
    expect(call_count).to eq(2)
    expect(DeviceToken.exists?(first.id)).to be(true)
    expect(DeviceToken.exists?(second.id)).to be(true)
  end
end
