require "rails_helper"

RSpec.describe Notification, type: :model do
  def team_slot(event, slot)
    event.event_teams.find_by!(slot: slot)
  end

  describe "validations" do
    it "requires a kind" do
      notification = build(:notification, kind: nil)
      expect(notification).not_to be_valid
      expect(notification.errors[:kind]).to be_present
    end

    it "does not define a created kind" do
      expect(described_class.kinds).not_to have_key("created")
    end

    it "defines all MVP kinds including reminder" do
      expect(described_class.kinds.keys).to contain_exactly(
        "updated", "canceled", "reminder", "joined", "left", "invited", "friendship_requested"
      )
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
    it "enqueues one notification delivery job" do
      user = create(:user)
      event = create(:event)

      expect {
        described_class.deliver_one!(
          user: user,
          kind: :invited,
          notifiable: event,
          payload: { title: event.title }
        )
      }.to have_enqueued_job(Notifications::DeliverOneJob)
        .with(hash_including(user_id: user.id, kind: "invited"))
    end

    it "enqueues many notification delivery job" do
      users = create_list(:user, 2)
      event = create(:event)

      expect {
        described_class.deliver_many!(
          user_ids: users.map(&:id),
          kind: :joined,
          notifiable: event,
          payload: { title: event.title, player: "Ada" }
        )
      }.to have_enqueued_job(Notifications::DeliverManyJob)
        .with(hash_including(user_ids: users.map(&:id), kind: "joined"))
    end

    it "creates one notification when the job runs", :notification_jobs do
      user = create(:user)
      event = create(:event)

      expect_any_instance_of(described_class).to receive(:broadcast_live!).and_call_original
      allow(Turbo::StreamsChannel).to receive(:broadcast_append_to)
      allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to)

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

    it "inserts many notifications when the job runs", :notification_jobs do
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

    it "skips friendship_requested when the friendship is no longer pending", :notification_jobs do
      friendship = create(:friendship, status: "pending")
      friendship.accept

      expect {
        described_class.deliver_one!(
          user: friendship.receiver,
          kind: :friendship_requested,
          notifiable: friendship,
          payload: { first_name: friendship.sender.first_name }
        )
      }.not_to change(described_class, :count)
    end
  end

  describe "generatable kinds", :notification_jobs do
    it "creates friendship_requested for the receiver of a pending friendship" do
      sender = create(:user)
      receiver = create(:user)

      expect {
        create(:friendship, sender: sender, receiver: receiver, status: "pending")
      }.to change { receiver.notifications.friendship_requested.count }.by(1)

      notification = receiver.notifications.friendship_requested.last
      expect(notification.notifiable).to be_a(Friendship)
      expect(notification.payload).to include("first_name" => sender.first_name)
      expect(receiver.notifications.inbox).not_to include(notification)
    end

    it "creates invited when an event invites a user" do
      event = create(:event)
      friend = create(:user)

      expect {
        event.invite!(users: [ friend ], sender: event.user)
      }.to change { friend.notifications.invited.count }.by(1)
        .and change { event.invitations.where(user: friend).count }.by(1)

      notification = friend.notifications.invited.last
      expect(notification.notifiable).to eq(event)
      expect(notification.payload).to include(
        "title" => event.title,
        "sender" => event.user.first_name
      )
      expect(notification.payload["start_time"]).to be_present
    end

    it "creates joined for other countable squad members when a player joins" do
      event = create(:event)
      teammate = create(:user)
      joiner = create(:user)
      create(:event_participant, user: teammate, event: event, event_team: team_slot(event, "team_two"))

      expect {
        create(:event_participant, user: joiner, event: event, event_team: team_slot(event, "team_one"))
      }.to change { teammate.notifications.joined.count }.by(1)
        .and change { event.user.notifications.joined.count }.by(1)
        .and change { joiner.notifications.joined.count }.by(0)

      notification = teammate.notifications.joined.last
      expect(notification.notifiable).to eq(event)
      expect(notification.payload).to include(
        "title" => event.title,
        "player" => joiner.first_name
      )
    end

    it "creates left for remaining countable and bench players when a player leaves" do
      event = create(:event)
      teammate = create(:user)
      bench_player = create(:user)
      leaving = create(:user)
      create(:event_participant, user: teammate, event: event, event_team: team_slot(event, "team_two"))
      create(:event_participant, user: bench_player, event: event, event_team: team_slot(event, "bench"))
      participant = create(:event_participant, user: leaving, event: event, event_team: team_slot(event, "team_one"))

      expect {
        participant.destroy!
      }.to change { teammate.notifications.left.count }.by(1)
        .and change { bench_player.notifications.left.count }.by(1)
        .and change { event.user.notifications.left.count }.by(1)
        .and change { leaving.notifications.left.count }.by(0)

      notification = teammate.notifications.left.last
      expect(notification.notifiable).to eq(event)
      expect(notification.payload).to include(
        "title" => event.title,
        "player" => leaving.first_name
      )
    end

    it "creates updated for participants except the author when a tracked field changes" do
      event = create(:event)
      player = create(:user)
      create(:event_participant, user: player, event: event, event_team: team_slot(event, "team_one"))

      expect {
        event.update!(price: 14.0)
      }.to change { player.notifications.updated.count }.by(1)
        .and change { event.user.notifications.updated.count }.by(0)

      notification = player.notifications.updated.last
      expect(notification.notifiable).to eq(event)
      expect(notification.payload).to include(
        "actor" => event.user.first_name,
        "field" => "price",
        "title" => event.title,
        "new_value" => "14.00"
      )
    end

    it "creates canceled with nil notifiable for participants when an event is destroyed" do
      event = create(:event)
      player = create(:user)
      create(:event_participant, user: player, event: event, event_team: team_slot(event, "team_one"))
      title = event.title
      author = event.user.first_name

      expect {
        event.destroy!
      }.to change { player.notifications.canceled.count }.by(1)
        .and change { event.user.notifications.canceled.count }.by(0)

      notification = player.notifications.canceled.last
      expect(notification.notifiable).to be_nil
      expect(notification.payload).to include(
        "title" => title,
        "author" => author
      )
    end
  end
end
