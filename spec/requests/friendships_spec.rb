require "rails_helper"

RSpec.describe "Friendships", type: :request do
  describe "PATCH /friendships/:id" do
    it "lets the receiver decline a pending friendship" do
      friendship = create(:friendship, status: "pending")
      sign_in friendship.receiver

      expect {
        patch friendship_path(friendship), params: { status: "declined" }
      }.to change { friendship.reload.status }.from("pending").to("declined")
        .and change { friendship.receiver.notifications.friendship_requested.count }.from(1).to(0)
    end

    it "rejects decline from the sender" do
      friendship = create(:friendship, status: "pending")
      sign_in friendship.sender

      expect {
        patch friendship_path(friendship), params: { status: "declined" }
      }.not_to change { friendship.reload.status }
    end

    it "rejects accepting a declined friendship" do
      friendship = create(:friendship, status: "declined")
      sign_in friendship.receiver

      expect {
        patch friendship_path(friendship)
      }.not_to change { friendship.reload.status }
    end
  end

  describe "DELETE /friendships/:id" do
    it "lets the receiver destroy a declined friendship" do
      friendship = create(:friendship, status: "declined")
      sign_in friendship.receiver

      expect {
        delete friendship_path(friendship)
      }.to change(Friendship, :count).by(-1)
    end

    it "rejects destroy of a declined friendship by the sender" do
      friendship = create(:friendship, status: "declined")
      sign_in friendship.sender

      expect {
        delete friendship_path(friendship)
      }.not_to change(Friendship, :count)
    end

    it "no longer destroys a pending friendship when the receiver deletes" do
      friendship = create(:friendship, status: "pending")
      sign_in friendship.receiver

      expect {
        delete friendship_path(friendship)
      }.not_to change(Friendship, :count)

      expect(friendship.reload.status).to eq("pending")
    end
  end
end
