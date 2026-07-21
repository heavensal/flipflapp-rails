# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1 Notifications", type: :request do
  describe "GET /api/v1/notifications" do
    it "lists inbox notifications" do
      user = create(:user)
      event = create(:event)
      notification = create(:notification, user: user, notifiable: event, kind: :invited)

      api_get "/api/v1/notifications", user: user

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).map { |n| n["id"] }).to include(notification.id)
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
end
