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
