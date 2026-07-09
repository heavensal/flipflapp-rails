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

  describe "countable capacity" do
    it "rejects joining a countable team when all countable slots are taken" do
      event = create(:event, number_of_participants: 2)
      create(:event_participant, user: create(:user), event: event, event_team: team_slot(event, "team_two"))

      late_player = build(:event_participant, user: create(:user), event: event, event_team: team_slot(event, "team_one"))

      expect(late_player).not_to be_valid
      expect(late_player.errors[:event_team]).to be_present
    end

    it "rejects joining a full countable team when the other team still has room" do
      event = create(:event, number_of_participants: 10)
      team_one = team_slot(event, "team_one")
      team_two = team_slot(event, "team_two")

      4.times do
        create(:event_participant, user: create(:user), event: event, event_team: team_one)
      end
      3.times do
        create(:event_participant, user: create(:user), event: event, event_team: team_two)
      end

      expect(event.participants_count).to eq(8)
      expect(team_one.full?).to be(true)
      expect(team_two.joinable?).to be(true)

      blocked = build(:event_participant, user: create(:user), event: event, event_team: team_one)
      allowed = build(:event_participant, user: create(:user), event: event, event_team: team_two)

      expect(blocked).not_to be_valid
      expect(blocked.errors[:event_team]).to be_present
      expect(allowed).to be_valid
    end

    it "rejects moving from one countable team to another when the target team is full" do
      event = create(:event, number_of_participants: 10)
      team_one = team_slot(event, "team_one")
      team_two = team_slot(event, "team_two")
      switching_player = create(:event_participant, user: create(:user), event: event, event_team: team_two)

      4.times do
        create(:event_participant, user: create(:user), event: event, event_team: team_one)
      end
      2.times do
        create(:event_participant, user: create(:user), event: event, event_team: team_two)
      end

      expect(switching_player.update(event_team: team_one)).to be(false)
      expect(switching_player.errors[:event_team]).to be_present
    end

    it "allows joining the bench when countable slots are full" do
      event = create(:event, number_of_participants: 2)
      create(:event_participant, user: create(:user), event: event, event_team: team_slot(event, "team_two"))

      bench_player = build(:event_participant, user: create(:user), event: event, event_team: team_slot(event, "bench"))

      expect(bench_player).to be_valid
    end

    it "rejects moving from bench to a countable team when slots are full" do
      event = create(:event, number_of_participants: 2)
      create(:event_participant, user: create(:user), event: event, event_team: team_slot(event, "team_two"))
      participant = create(:event_participant, user: create(:user), event: event, event_team: team_slot(event, "bench"))

      expect(participant.update(event_team: team_slot(event, "team_one"))).to be(false)
      expect(participant.errors[:event_team]).to be_present
    end

    it "allows moving between countable teams when the target team has room" do
      event = create(:event, number_of_participants: 4)
      team_two_player = create(:user)
      create(:event_participant, user: team_two_player, event: event, event_team: team_slot(event, "team_two"))
      participant = event.event_participants.find_by!(user: event.user)

      expect(participant.update(event_team: team_slot(event, "team_two"))).to be(true)
    end

    it "rejects moving between countable teams when the target team is full" do
      event = create(:event, number_of_participants: 2)
      create(:event_participant, user: create(:user), event: event, event_team: team_slot(event, "team_two"))
      participant = event.event_participants.find_by!(user: event.user)

      expect(participant.update(event_team: team_slot(event, "team_two"))).to be(false)
      expect(participant.errors[:event_team]).to be_present
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

  describe "switching EventTeam (update)" do
    it "notifies countable players when a bench player moves to a countable team" do
      event = create(:event)
      team_player = create(:user)
      bench_player = create(:user)
      participant = create(:event_participant, user: bench_player, event: event, event_team: team_slot(event, "bench"))

      create(:event_participant, user: team_player, event: event, event_team: team_slot(event, "team_two"))

      expect {
        participant.update!(event_team: team_slot(event, "team_one"))
      }.to change { event.user.notifications.where(kind: :joined).count }.by(1)
        .and change { team_player.notifications.where(kind: :joined).count }.by(1)
        .and change { Notification.where(kind: :left).count }.by(0)
    end

    it "notifies countable players when a player moves from a countable team to the bench" do
      event = create(:event)
      team_player = create(:user)
      bench_player = create(:user)
      participant = create(:event_participant, user: bench_player, event: event, event_team: team_slot(event, "team_one"))

      create(:event_participant, user: team_player, event: event, event_team: team_slot(event, "team_two"))

      expect {
        participant.update!(event_team: team_slot(event, "bench"))
      }.to change { event.user.notifications.where(kind: :left).count }.by(1)
        .and change { team_player.notifications.where(kind: :left).count }.by(1)
        .and change { Notification.where(kind: :joined).count }.by(0)
    end

    it "does not notify when a player moves between countable teams" do
      event = create(:event)
      team_player = create(:user)
      switching_player = create(:user)
      participant = create(:event_participant, user: switching_player, event: event, event_team: team_slot(event, "team_one"))

      create(:event_participant, user: team_player, event: event, event_team: team_slot(event, "team_two"))

      expect {
        participant.update!(event_team: team_slot(event, "team_two"))
      }.not_to change { Notification.count }
    end

    it "does not notify when a bench player switches to the bench again" do
      event = create(:event)
      player = create(:user)
      participant = create(:event_participant, user: player, event: event, event_team: team_slot(event, "bench"))

      expect {
        participant.update!(event_team: team_slot(event, "bench"))
      }.not_to change { Notification.count }
    end
  end
end
