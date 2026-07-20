require "rails_helper"

RSpec.describe "Notifications", type: :request do
  describe "PATCH /notifications/:id/read" do
    it "marks a friendship request toast as read and navigates to friendships" do
      friendship = create(:friendship, status: "pending")
      notification = create(
        :notification,
        user: friendship.receiver,
        kind: :friendship_requested,
        notifiable: friendship
      )
      sign_in friendship.receiver

      patch read_notification_path(notification), params: { navigate: 1 }

      expect(notification.reload.read).to be(true)
      expect(response).to redirect_to(friendships_path)
    end
  end
end
