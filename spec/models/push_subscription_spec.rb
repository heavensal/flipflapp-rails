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
end
