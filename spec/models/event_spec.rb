require "rails_helper"

RSpec.describe Event, type: :model do
  describe "validations" do
    it "requires title, location, and start_time" do
      event = build(:event, title: nil, location: nil, start_time: nil)
      expect(event).not_to be_valid
      expect(event.errors[:title]).to be_present
      expect(event.errors[:location]).to be_present
      expect(event.errors[:start_time]).to be_present
    end

    it "rejects a start time in the past" do
      event = build(:event, start_time: 1.day.ago)
      expect(event).not_to be_valid
      expect(event.errors[:start_time]).to be_present
    end

    it "rejects non-positive participant counts" do
      event = build(:event, number_of_participants: 0)
      expect(event).not_to be_valid
      expect(event.errors[:number_of_participants]).to be_present
    end
  end

  describe "after_create" do
    it "creates default teams and registers the author as a participant" do
      event = create(:event)

      expect(event.event_teams.pluck(:name)).to contain_exactly("Equipe 1", "Equipe 2", "Sur le Banc")
      expect(event.event_participants.map(&:user_id)).to include(event.user_id)
    end
  end

  describe "notifications" do
    it "creates one update notification per tracked field for every participant except the author" do
      event = create(:event)
      player = create(:user)
      bench_player = create(:user)

      create(:event_participant, user: player, event: event, event_team: event.event_teams.first)
      create(:event_participant, user: bench_player, event: event, event_team: event.event_teams.third)

      expect {
        event.update!(title: "Match retour", price: 14.0)
      }.to change { player.notifications.where(kind: :updated).count }.by(2)
        .and change { bench_player.notifications.where(kind: :updated).count }.by(2)
        .and change { event.user.notifications.where(kind: :updated).count }.by(0)
    end

    it "stores the actor, field, event title, and new value in update notifications" do
      event = create(:event)
      player = create(:user)

      create(:event_participant, user: player, event: event, event_team: event.event_teams.first)
      event.update!(price: 14.0)

      notification = player.notifications.updated.order(:created_at).last

      expect(notification.payload).to include(
        "actor" => event.user.first_name,
        "field" => "price",
        "title" => event.title,
        "new_value" => "14.00"
      )
    end

    it "does not notify participants when untracked event attributes change" do
      event = create(:event)
      player = create(:user)

      create(:event_participant, user: player, event: event, event_team: event.event_teams.first)

      expect {
        event.update!(description: "Nouvelle description", location: "Lyon", is_private: false)
      }.not_to change { Notification.where(kind: :updated).count }
    end

    it "notifies all participants except the author when the event is destroyed" do
      event = create(:event)
      player = create(:user)
      bench_player = create(:user)

      create(:event_participant, user: player, event: event, event_team: event.event_teams.first)
      create(:event_participant, user: bench_player, event: event, event_team: event.event_teams.third)

      expect {
        event.destroy!
      }.to change { player.notifications.where(kind: :canceled).count }.by(1)
        .and change { bench_player.notifications.where(kind: :canceled).count }.by(1)
        .and change { event.user.notifications.where(kind: :canceled).count }.by(0)
    end

    it "removes previous notifications linked to a destroyed event" do
      event = create(:event)
      player = create(:user)

      create(:event_participant, user: player, event: event, event_team: event.event_teams.first)
      create(:notification, user: player, notifiable: event, kind: :joined)
      create(:notification, user: player, notifiable: event, kind: :updated)

      event.destroy!

      expect(Notification.where(notifiable_type: "Event", notifiable_id: event.id)).to be_empty
      expect(player.notifications.canceled.last.notifiable).to be_nil
    end
  end

  describe "access rules" do
    it "allows participants to invite friends" do
      event = create(:event)
      player = create(:user)
      stranger = create(:user)

      create(:event_participant, user: player, event: event, event_team: event.event_teams.first)

      expect(event.can_invite?(event.user)).to be(true)
      expect(event.can_invite?(player)).to be(true)
      expect(event.can_invite?(stranger)).to be(false)
    end

    it "allows an invited friend to view and join a private event" do
      event = create(:event, is_private: true)
      invited_friend = create(:user)

      create(:notification, user: invited_friend, notifiable: event, kind: :invited)

      expect(event.viewable_by?(invited_friend)).to be(true)
      expect(event.joinable_by?(invited_friend)).to be(true)
    end

    it "blocks strangers from viewing or joining a private event" do
      event = create(:event, is_private: true)
      stranger = create(:user)

      expect(event.viewable_by?(stranger)).to be(false)
      expect(event.joinable_by?(stranger)).to be(false)
    end
  end
end
