require "rails_helper"

RSpec.describe EventParticipant, type: :model do
  def team_slot(event, slot)
    event.event_teams.find_by!(slot: slot)
  end

  describe "validations" do
    it "rejects duplicate registration for the same event" do
      event = create(:event)
      player = create(:user)
      create(:event_participant, user: player, event: event)

      duplicate = build(:event_participant, user: player, event: event, event_team: team_slot(event, "team_two"))
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to be_present
    end
  end

  describe "data side effects" do
    it "does not notify anyone when the event author is automatically registered" do
      expect {
        create(:event)
      }.not_to change { Notification.where(kind: :joined).count }
    end

    it "notifies team players when a player joins team_one or team_two" do
      event = create(:event)
      team_player = create(:user)
      bench_player = create(:user)
      new_player = create(:user)

      create(:event_participant, user: team_player, event: event, event_team: team_slot(event, "team_two"))
      create(:event_participant, user: bench_player, event: event, event_team: team_slot(event, "bench"))

      author_count = event.user.notifications.where(kind: :joined).count
      team_player_count = team_player.notifications.where(kind: :joined).count
      bench_player_count = bench_player.notifications.where(kind: :joined).count
      new_player_count = new_player.notifications.where(kind: :joined).count

      create(:event_participant, user: new_player, event: event, event_team: team_slot(event, "team_one"))

      expect(event.user.notifications.where(kind: :joined).count).to eq(author_count + 1)
      expect(team_player.notifications.where(kind: :joined).count).to eq(team_player_count + 1)
      expect(bench_player.notifications.where(kind: :joined).count).to eq(bench_player_count)
      expect(new_player.notifications.where(kind: :joined).count).to eq(new_player_count)
    end

    it "still notifies when team_one has a custom label" do
      event = create(:event)
      team_slot(event, "team_one").update!(label: "Real Madrid")
      team_player = create(:user)
      new_player = create(:user)

      create(:event_participant, user: team_player, event: event, event_team: team_slot(event, "team_two"))

      expect {
        create(:event_participant, user: new_player, event: event, event_team: team_slot(event, "team_one"))
      }.to change { team_player.notifications.where(kind: :joined).count }.by(1)
    end

    it "does not notify anyone when a player joins the bench" do
      event = create(:event)
      player = create(:user)

      expect {
        create(:event_participant, user: player, event: event, event_team: team_slot(event, "bench"))
      }.not_to change { Notification.where(kind: :joined).count }
    end

    it "notifies remaining team players when a player leaves team_one or team_two" do
      event = create(:event)
      player = create(:user)
      team_player = create(:user)
      bench_player = create(:user)
      participant = create(:event_participant, user: player, event: event, event_team: team_slot(event, "team_one"))

      create(:event_participant, user: team_player, event: event, event_team: team_slot(event, "team_two"))
      create(:event_participant, user: bench_player, event: event, event_team: team_slot(event, "bench"))

      author_count = event.user.notifications.where(kind: :left).count
      team_player_count = team_player.notifications.where(kind: :left).count
      bench_player_count = bench_player.notifications.where(kind: :left).count
      leaving_player_count = player.notifications.where(kind: :left).count

      participant.destroy!

      expect(event.user.notifications.where(kind: :left).count).to eq(author_count + 1)
      expect(team_player.notifications.where(kind: :left).count).to eq(team_player_count + 1)
      expect(bench_player.notifications.where(kind: :left).count).to eq(bench_player_count)
      expect(player.notifications.where(kind: :left).count).to eq(leaving_player_count)
    end

    it "still notifies when leaving team_two with a custom label" do
      event = create(:event)
      team_slot(event, "team_two").update!(label: "Barcelone")
      player = create(:user)
      team_player = create(:user)
      participant = create(:event_participant, user: player, event: event, event_team: team_slot(event, "team_two"))

      create(:event_participant, user: team_player, event: event, event_team: team_slot(event, "team_one"))

      expect {
        participant.destroy!
      }.to change { team_player.notifications.where(kind: :left).count }.by(1)
    end

    it "does not notify anyone when a player leaves the bench" do
      event = create(:event)
      player = create(:user)
      participant = create(:event_participant, user: player, event: event, event_team: team_slot(event, "bench"))

      expect {
        participant.destroy!
      }.not_to change { Notification.where(kind: :left).count }
    end
  end
end
