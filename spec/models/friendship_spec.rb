require "rails_helper"

RSpec.describe Friendship, type: :model do
  describe "validations" do
    it "requires a valid status" do
      friendship = build(:friendship, status: "invalid")
      expect(friendship).not_to be_valid
      expect(friendship.errors[:status]).to be_present
    end

    it "rejects self-friendship" do
      user = create(:user)
      friendship = build(:friendship, sender: user, receiver: user)
      expect(friendship).not_to be_valid
      expect(friendship.errors[:receiver_id]).to be_present
    end

    it "rejects duplicate requests between the same users" do
      friendship = create(:friendship)
      duplicate = build(:friendship, sender: friendship.sender, receiver: friendship.receiver)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:sender_id]).to be_present
    end
  end

  describe "CRUD" do
    it "accepts a pending friendship" do
      friendship = create(:friendship, status: "pending")
      friendship.accept
      expect(friendship.reload.status).to eq("accepted")
    end
  end

  describe "notifications" do
    it "creates a friendship_requested notification for the receiver" do
      sender = create(:user)
      receiver = create(:user)

      expect {
        create(:friendship, sender: sender, receiver: receiver, status: "pending")
      }.to change { receiver.notifications.friendship_requested.count }.by(1)

      notification = receiver.notifications.friendship_requested.last
      expect(notification.notifiable).to be_a(Friendship)
      expect(notification.payload["first_name"]).to eq(sender.first_name)
    end

    it "hides friendship_requested from the inbox scope" do
      friendship = create(:friendship, status: "pending")
      notification = friendship.receiver.notifications.friendship_requested.last

      expect(friendship.receiver.notifications.inbox).not_to include(notification)
    end

    it "removes the notification when the friendship is accepted" do
      friendship = create(:friendship, status: "pending")
      receiver = friendship.receiver

      expect {
        friendship.accept
      }.to change { receiver.notifications.friendship_requested.count }.from(1).to(0)
    end

    it "removes the notification when the friendship is destroyed" do
      friendship = create(:friendship, status: "pending")
      receiver = friendship.receiver

      expect {
        friendship.destroy!
      }.to change { receiver.notifications.friendship_requested.count }.from(1).to(0)
    end
  end
end
