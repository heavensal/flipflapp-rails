require "rails_helper"

RSpec.describe Notification, type: :model do
  describe "validations" do
    it "requires a kind" do
      notification = build(:notification, kind: nil)
      expect(notification).not_to be_valid
      expect(notification.errors[:kind]).to be_present
    end
  end

  describe "CRUD" do
    it "marks a notification as read" do
      notification = create(:notification, read: false)
      notification.mark_as_read!
      expect(notification.reload.read).to be(true)
    end
  end

  describe "links" do
    it "is clickable when it has a notifiable record" do
      event = create(:event)
      notification = create(:notification, notifiable: event)

      expect(notification).to be_clickable
      expect(notification.target_url).to eq("/events/#{event.id}")
    end

    it "is not clickable without a notifiable record" do
      notification = create(:notification, notifiable: nil)

      expect(notification).not_to be_clickable
      expect(notification.target_url).to be_nil
    end
  end
end
