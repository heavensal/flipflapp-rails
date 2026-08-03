# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1 Notifications", type: :request do
  describe "GET /api/v1/notifications" do
    it "lists inbox notifications and excludes friendship_requested" do
      user = create(:user)
      event = create(:event)
      invited = create(:notification, user: user, notifiable: event, kind: :invited)
      friendship = create(:friendship, receiver: user)
      create(:notification, user: user, notifiable: friendship, kind: :friendship_requested)

      api_get "/api/v1/notifications", user: user

      expect(response).to have_http_status(:ok)
      ids = JSON.parse(response.body).map { |n| n["id"] }
      expect(ids).to include(invited.id)
      expect(ids).not_to include(
        user.notifications.find_by!(kind: :friendship_requested).id
      )
    end

    it "returns at most 20 newest first" do
      user = create(:user)
      event = create(:event)
      21.times do |i|
        create(:notification, user: user, notifiable: event, kind: :invited,
                              created_at: i.minutes.ago)
      end

      api_get "/api/v1/notifications", user: user

      body = JSON.parse(response.body)
      expect(body.size).to eq(20)
      expect(body.first["created_at"]).to be >= body.last["created_at"]
    end
  end

  describe "PATCH /api/v1/notifications/:id/read" do
    it "marks a notification as read" do
      user = create(:user)
      event = create(:event)
      notification = create(:notification, user: user, notifiable: event, kind: :invited, read: false)

      api_patch "/api/v1/notifications/#{notification.id}/read", user: user

      expect(response).to have_http_status(:ok)
      expect(notification.reload.read).to be(true)
    end

    it "returns 404 for friendship_requested id (not inbox)" do
      user = create(:user)
      friendship = create(:friendship, receiver: user)
      notification = create(:notification, user: user, notifiable: friendship, kind: :friendship_requested)

      api_patch "/api/v1/notifications/#{notification.id}/read", user: user

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /api/v1/notifications/read_all" do
    it "marks all inbox notifications as read" do
      user = create(:user)
      event = create(:event)
      create(:notification, user: user, notifiable: event, kind: :invited, read: false)

      api_patch "/api/v1/notifications/read_all", user: user

      expect(response).to have_http_status(:no_content)
      expect(user.notifications.inbox.unread.count).to eq(0)
    end
  end

  describe "DELETE /api/v1/notifications/:id" do
    it "destroys an inbox notification" do
      user = create(:user)
      event = create(:event)
      notification = create(:notification, user: user, notifiable: event, kind: :invited)

      api_delete "/api/v1/notifications/#{notification.id}", user: user

      expect(response).to have_http_status(:no_content)
      expect(Notification.find_by(id: notification.id)).to be_nil
    end

    it "returns 404 for another user's notification" do
      owner = create(:user)
      other = create(:user)
      event = create(:event)
      notification = create(:notification, user: owner, notifiable: event, kind: :invited)

      api_delete "/api/v1/notifications/#{notification.id}", user: other

      expect(response).to have_http_status(:not_found)
      expect(notification.reload).to be_present
    end
  end
end
