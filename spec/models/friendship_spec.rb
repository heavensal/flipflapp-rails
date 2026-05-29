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
end
