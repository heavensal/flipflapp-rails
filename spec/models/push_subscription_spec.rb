# frozen_string_literal: true

require "rails_helper"

RSpec.describe PushSubscription, type: :model do
  describe "validations" do
    subject { build(:push_subscription) }

    it { is_expected.to be_valid }

    it "requires endpoint, p256dh, and auth" do
      subscription = build(:push_subscription, endpoint: nil, p256dh: nil, auth: nil)

      expect(subscription).not_to be_valid
      expect(subscription.errors[:endpoint]).to be_present
      expect(subscription.errors[:p256dh]).to be_present
      expect(subscription.errors[:auth]).to be_present
    end

    it "enforces unique endpoints" do
      existing = create(:push_subscription)

      duplicate = build(:push_subscription, endpoint: existing.endpoint)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:endpoint]).to be_present
    end
  end

  describe "associations" do
    it "belongs to a user and is destroyed with the user" do
      user = create(:user)
      create(:push_subscription, user: user)

      expect { user.destroy! }.to change(described_class, :count).by(-1)
    end
  end

  describe ".register_for" do
    it "creates a subscription for the user" do
      user = create(:user)

      expect {
        described_class.register_for(
          user,
          endpoint: "https://fcm.googleapis.com/fcm/send/abc",
          p256dh: "key",
          auth: "secret"
        ).save!
      }.to change(user.push_subscriptions, :count).by(1)
    end

    it "updates keys when the endpoint already belongs to the user" do
      user = create(:user)
      subscription = create(:push_subscription, user: user, p256dh: "old", auth: "old")

      described_class.register_for(
        user,
        endpoint: subscription.endpoint,
        p256dh: "new-key",
        auth: "new-auth"
      ).save!

      expect(subscription.reload.p256dh).to eq("new-key")
      expect(subscription.auth).to eq("new-auth")
    end

    it "reassigns an endpoint from another user on a shared browser" do
      previous_owner = create(:user)
      current_user = create(:user)
      subscription = create(:push_subscription, user: previous_owner, p256dh: "old", auth: "old")

      expect {
        described_class.register_for(
          current_user,
          endpoint: subscription.endpoint,
          p256dh: "new-key",
          auth: "new-auth"
        ).save!
      }.not_to change(described_class, :count)

      subscription.reload
      expect(subscription.user).to eq(current_user)
      expect(subscription.p256dh).to eq("new-key")
      expect(subscription.auth).to eq("new-auth")
      expect(previous_owner.push_subscriptions).to be_empty
    end
  end
end
