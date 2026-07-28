# frozen_string_literal: true

require "rails_helper"

RSpec.describe DeviceToken, type: :model do
  describe "validations" do
    subject { build(:device_token) }

    it { is_expected.to be_valid }

    it "requires token and a known platform" do
      device_token = build(:device_token, token: nil, platform: "web")

      expect(device_token).not_to be_valid
      expect(device_token.errors[:token]).to be_present
      expect(device_token.errors[:platform]).to be_present
    end

    it "enforces unique tokens" do
      existing = create(:device_token)
      duplicate = build(:device_token, token: existing.token)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:token]).to be_present
    end
  end

  describe "associations" do
    it "belongs to a user and is destroyed with the user" do
      user = create(:user)
      create(:device_token, user: user)

      expect { user.destroy! }.to change(DeviceToken, :count).by(-1)
    end
  end

  describe ".register_for" do
    it "creates a token for the user" do
      user = create(:user)

      expect {
        DeviceToken.register_for(user, token: "abc", platform: "android").save!
      }.to change(user.device_tokens, :count).by(1)
    end

    it "reassigns an existing token to a new user" do
      previous_owner = create(:user)
      new_owner = create(:user)
      device_token = create(:device_token, user: previous_owner, token: "shared", platform: "android")

      DeviceToken.register_for(new_owner, token: "shared", platform: "ios").save!

      expect(device_token.reload.user).to eq(new_owner)
      expect(device_token.platform).to eq("ios")
      expect(previous_owner.device_tokens).to be_empty
    end
  end
end
