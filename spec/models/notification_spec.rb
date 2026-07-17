require "rails_helper"

RSpec.describe Notification, type: :model do
  describe "validations" do
    it "requires a kind" do
      notification = build(:notification, kind: nil)
      expect(notification).not_to be_valid
      expect(notification.errors[:kind]).to be_present
    end

    it "does not define a created kind" do
      expect(described_class.kinds).not_to have_key("created")
    end

    it "defines friendship_requested" do
      expect(described_class.kinds).to have_key("friendship_requested")
    end
  end

  describe "scopes" do
    it "excludes friendship_requested from inbox" do
      user = create(:user)
      inbox_notification = create(:notification, user: user, kind: :invited)
      hidden = create(:notification, user: user, kind: :friendship_requested)

      expect(user.notifications.inbox).to contain_exactly(inbox_notification)
      expect(user.notifications.inbox).not_to include(hidden)
    end

    it "counts unread only within inbox" do
      user = create(:user)
      create(:notification, user: user, kind: :invited, read: false)
      create(:notification, user: user, kind: :friendship_requested, read: false)
      create(:notification, user: user, kind: :joined, read: true)

      expect(user.notifications.inbox.unread.count).to eq(1)
    end
  end

  describe "CRUD" do
    it "marks a notification as read" do
      notification = create(:notification, read: false)
      notification.mark_as_read!
      expect(notification.reload.read).to be(true)
    end

    it "marks all inbox notifications as read for a user" do
      user = create(:user)
      a = create(:notification, user: user, kind: :invited, read: false)
      b = create(:notification, user: user, kind: :joined, read: false)
      hidden = create(:notification, user: user, kind: :friendship_requested, read: false)

      expect {
        described_class.mark_all_as_read_for!(user)
      }.to change { a.reload.read }.from(false).to(true)
        .and change { b.reload.read }.from(false).to(true)

      expect(hidden.reload.read).to be(false)
    end
  end

  describe "links" do
    it "is clickable when it has a notifiable record" do
      event = create(:event)
      notification = create(:notification, notifiable: event)

      expect(notification).to be_clickable
      expect(notification.target_url).to eq("/events/#{event.id}")
    end

    it "targets friendships path for a Friendship notifiable" do
      friendship = create(:friendship)
      notification = create(
        :notification,
        user: friendship.receiver,
        notifiable: friendship,
        kind: :friendship_requested
      )

      expect(notification).to be_clickable
      expect(notification.target_url).to eq("/friendships")
    end

    it "is not clickable without a notifiable record" do
      notification = create(:notification, notifiable: nil)

      expect(notification).not_to be_clickable
      expect(notification.target_url).to be_nil
    end
  end

  describe "Delivery" do
    it "delivers one notification" do
      user = create(:user)
      event = create(:event)

      expect {
        described_class.deliver_one!(
          user: user,
          kind: :invited,
          notifiable: event,
          payload: { title: event.title }
        )
      }.to change(described_class, :count).by(1)

      notification = user.notifications.last
      expect(notification.kind).to eq("invited")
      expect(notification.notifiable).to eq(event)
      expect(notification.payload["title"]).to eq(event.title)
    end

    it "delivers many notifications in one insert" do
      users = create_list(:user, 2)
      event = create(:event)

      expect(described_class).to receive(:insert_all).once.and_call_original

      expect {
        described_class.deliver_many!(
          user_ids: users.map(&:id),
          kind: :joined,
          notifiable: event,
          payload: { title: event.title, player: "Ada" }
        )
      }.to change(described_class, :count).by(2)
    end
  end
end
