require "rails_helper"

RSpec.describe Event, type: :model do
  def team_slot(event, slot)
    event.event_teams.find_by!(slot: slot)
  end

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

    it "rejects a price that is not a whole euro" do
      event = build(:event, price: 10.5)
      expect(event).not_to be_valid
      expect(event.errors[:price]).to be_present
    end

    it "accepts a whole-euro price" do
      event = build(:event, price: 10.0)
      expect(event).to be_valid
    end

    it "requires latitude and longitude" do
      event = build(:event, latitude: nil, longitude: nil)
      expect(event).not_to be_valid
      expect(event.errors[:latitude]).to be_present
      expect(event.errors[:longitude]).to be_present
    end
  end

  describe "after_create" do
    it "creates three teams with fixed slots and localized default labels" do
      event = create(:event)

      expect(event.event_teams.pluck(:slot)).to contain_exactly("team_one", "team_two", "bench")
      expect(team_slot(event, "team_one").label).to eq(I18n.t("event_team.slots.team_one.default_label"))
      expect(team_slot(event, "team_two").label).to eq(I18n.t("event_team.slots.team_two.default_label"))
      expect(team_slot(event, "bench").label).to eq(I18n.t("event_team.slots.bench.default_label"))
    end

    it "uses the active locale for default labels" do
      I18n.with_locale(:en) do
        event = create(:event)

        expect(team_slot(event, "team_one").label).to eq("Team 1")
        expect(team_slot(event, "team_two").label).to eq("Team 2")
        expect(team_slot(event, "bench").label).to eq("On the bench")
      end
    end

    it "registers the author on team_one" do
      event = create(:event)
      author_participant = event.event_participants.find_by!(user: event.user)

      expect(author_participant.event_team).to eq(team_slot(event, "team_one"))
    end
  end

  describe "#participants_count" do
    it "counts players on countable teams (team_one and team_two) only" do
      event = create(:event)
      player = create(:user)
      bench_player = create(:user)

      create(:event_participant, user: player, event: event, event_team: team_slot(event, "team_one"))
      create(:event_participant, user: bench_player, event: event, event_team: team_slot(event, "bench"))

      expect(event.participants_count).to eq(2)
    end

    it "still excludes bench when the bench label looks like a countable team" do
      event = create(:event)
      bench_player = create(:user)
      team_slot(event, "bench").update_column(:label, "Equipe 1 bis")

      create(:event_participant, user: bench_player, event: event, event_team: team_slot(event, "bench"))

      expect(event.participants_count).to eq(1)
    end
  end

  describe "#registrations_count" do
    it "counts every EventParticipant including bench players" do
      event = create(:event)
      player = create(:user)
      bench_player = create(:user)

      create(:event_participant, user: player, event: event, event_team: team_slot(event, "team_one"))
      create(:event_participant, user: bench_player, event: event, event_team: team_slot(event, "bench"))

      expect(event.registrations_count).to eq(3)
      expect(event.participants_count).to eq(2)
    end

    it "keeps registrations_count unchanged when a player moves to the bench" do
      event = create(:event)
      player = create(:user)
      participant = create(:event_participant, user: player, event: event, event_team: team_slot(event, "team_one"))

      expect { participant.update!(event_team: team_slot(event, "bench")) }
        .to change { event.reload.participants_count }.from(2).to(1)

      expect(event.registrations_count).to eq(2)
    end

    it "updates participants_count but not registrations_count when a bench player joins a countable team" do
      event = create(:event)
      player = create(:user)
      participant = create(:event_participant, user: player, event: event, event_team: team_slot(event, "bench"))

      expect { participant.update!(event_team: team_slot(event, "team_two")) }
        .to change { event.reload.participants_count }.from(1).to(2)

      expect(event.registrations_count).to eq(2)
    end
  end

  describe "#countable_slots" do
    it "reports when countable slots are full" do
      event = create(:event, number_of_participants: 2)
      create(:event_participant, user: create(:user), event: event, event_team: team_slot(event, "team_two"))

      expect(event.countable_slots_full?).to be(true)
      expect(event.countable_slots_per_team).to eq(1)
    end

    it "gives team_one floor(n/2) and team_two ceil(n/2) when n is odd" do
      event = create(:event, number_of_participants: 11)

      expect(event.countable_slots_for(team_slot(event, "team_one"))).to eq(5)
      expect(event.countable_slots_for(team_slot(event, "team_two"))).to eq(6)
    end
  end

  describe "#fill_level" do
    it "returns open, tight, or full from countable occupancy" do
      open_event = create(:event, number_of_participants: 10)
      tight_event = create(:event, number_of_participants: 3)
      create(:event_participant, user: create(:user), event: tight_event, event_team: team_slot(tight_event, "team_two"))
      full_event = create(:event, number_of_participants: 2)
      create(:event_participant, user: create(:user), event: full_event, event_team: team_slot(full_event, "team_two"))

      expect(open_event.fill_level).to eq(:open)
      expect(tight_event.fill_level).to eq(:tight)
      expect(full_event.fill_level).to eq(:full)
    end
  end

  describe ".with_countable_participants_count" do
    it "loads participants_count without a per-record query" do
      event = create(:event)
      create(:event_participant, user: create(:user), event: event, event_team: team_slot(event, "team_two"))

      loaded = described_class.with_countable_participants_count.find(event.id)

      expect(loaded.participants_count).to eq(2)
      expect(loaded.has_attribute?(:countable_participants_count)).to be(true)
    end
  end

  describe "notifications", :notification_jobs do
    it "creates one update notification per tracked field for every participant except the author" do
      event = create(:event)
      player = create(:user)
      bench_player = create(:user)

      create(:event_participant, user: player, event: event, event_team: team_slot(event, "team_one"))
      create(:event_participant, user: bench_player, event: event, event_team: team_slot(event, "bench"))

      expect {
        event.update!(title: "Match retour", price: 14.0)
      }.to change { player.notifications.where(kind: :updated).count }.by(2)
        .and change { bench_player.notifications.where(kind: :updated).count }.by(2)
        .and change { event.user.notifications.where(kind: :updated).count }.by(0)
    end

    it "stores the actor, field, event title, and new value in update notifications" do
      event = create(:event)
      player = create(:user)

      create(:event_participant, user: player, event: event, event_team: team_slot(event, "team_one"))
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

      create(:event_participant, user: player, event: event, event_team: team_slot(event, "team_one"))

      expect {
        event.update!(description: "Nouvelle description", location: "Lyon", is_private: false)
      }.not_to change { Notification.where(kind: :updated).count }
    end

    it "notifies all participants except the author when the event is destroyed" do
      event = create(:event)
      player = create(:user)
      bench_player = create(:user)

      create(:event_participant, user: player, event: event, event_team: team_slot(event, "team_one"))
      create(:event_participant, user: bench_player, event: event, event_team: team_slot(event, "bench"))

      expect {
        event.destroy!
      }.to change { player.notifications.where(kind: :canceled).count }.by(1)
        .and change { bench_player.notifications.where(kind: :canceled).count }.by(1)
        .and change { event.user.notifications.where(kind: :canceled).count }.by(0)
    end

    it "removes previous notifications linked to a destroyed event" do
      event = create(:event)
      player = create(:user)

      create(:event_participant, user: player, event: event, event_team: team_slot(event, "team_one"))
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

      create(:event_participant, user: player, event: event, event_team: team_slot(event, "team_one"))

      expect(event.can_invite?(event.user)).to be(true)
      expect(event.can_invite?(player)).to be(true)
      expect(event.can_invite?(stranger)).to be(false)
    end

    it "creates an invitation and invited notification via invite!", :notification_jobs do
      event = create(:event)
      friend = create(:user)

      expect {
        event.invite!(users: [ friend ], sender: event.user)
      }.to change { event.invitations.where(user: friend).count }.by(1)
        .and change { friend.notifications.invited.count }.by(1)

      notification = friend.notifications.invited.last
      expect(notification.notifiable).to eq(event)
      expect(notification.payload["sender"]).to eq(event.user.first_name)
    end

    it "does not create a duplicate invitation when invite! is called again", :notification_jobs do
      event = create(:event)
      friend = create(:user)
      event.invite!(users: [ friend ], sender: event.user)

      expect {
        event.invite!(users: [ friend ], sender: event.user)
      }.not_to change { event.invitations.where(user: friend).count }

      expect(friend.notifications.invited.count).to eq(1)
    end

    it "allows an accepted friend of the author to view and join a private event" do
      event = create(:event, is_private: true)
      friend = create(:user)
      create(:friendship, sender: event.user, receiver: friend, status: "accepted")

      expect(event.viewable_by?(friend)).to be(true)
      expect(event.joinable_by?(friend)).to be(true)
    end

    it "allows an invited user to view and join a private event" do
      event = create(:event, is_private: true)
      invited_user = create(:user)

      create(:invitation, event: event, user: invited_user)

      expect(event.invited?(invited_user)).to be(true)
      expect(event.viewable_by?(invited_user)).to be(true)
      expect(event.joinable_by?(invited_user)).to be(true)
    end

    it "includes private events for invited users in visible_to" do
      viewer = create(:user)
      event = create(:event, is_private: true)
      create(:invitation, event: event, user: viewer)

      expect(described_class.visible_to(viewer)).to include(event)
    end

    it "blocks strangers from viewing or joining a private event" do
      event = create(:event, is_private: true)
      stranger = create(:user)

      expect(event.viewable_by?(stranger)).to be(false)
      expect(event.joinable_by?(stranger)).to be(false)
    end
  end

  describe ".visible_to" do
    it "includes private events from accepted friendship friends who are the author" do
      viewer = create(:user)
      friend = create(:user)
      stranger = create(:user)
      create(:friendship, sender: viewer, receiver: friend, status: "accepted")

      own_private = create(:event, user: viewer, is_private: true)
      friend_private = create(:event, user: friend, is_private: true)
      stranger_private = create(:event, user: stranger, is_private: true)
      public_event = create(:event, user: stranger, is_private: false)

      expect(described_class.visible_to(viewer)).to include(own_private, friend_private, public_event)
      expect(described_class.visible_to(viewer)).not_to include(stranger_private)
    end
  end

  describe ".private_visible_to" do
    it "returns only private events authored by the user or accepted friends" do
      viewer = create(:user)
      friend = create(:user)
      stranger = create(:user)
      create(:friendship, sender: friend, receiver: viewer, status: "accepted")

      own_private = create(:event, user: viewer, is_private: true)
      friend_private = create(:event, user: friend, is_private: true)
      stranger_private = create(:event, user: stranger, is_private: true)
      public_event = create(:event, user: friend, is_private: false)

      expect(described_class.private_visible_to(viewer)).to contain_exactly(own_private, friend_private)
      expect(described_class.private_visible_to(viewer)).not_to include(stranger_private, public_event)
    end
  end
end
