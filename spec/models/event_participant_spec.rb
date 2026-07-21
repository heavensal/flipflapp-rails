require "rails_helper"

RSpec.describe EventParticipant, type: :model do
  def team_slot(event, slot)
    event.event_teams.find_by!(slot: slot)
  end

  describe "validations" do
    it "rejects a duplicate registration on the same Event" do
      event = create(:event)
      player = create(:user)
      create(:event_participant, user: player, event: event)

      duplicate = build(:event_participant, user: player, event: event, event_team: team_slot(event, "team_two"))
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to include(I18n.t("activerecord.errors.models.event_participant.attributes.user_id.taken"))
    end
  end

  describe "invitation cleanup" do
    it "destroys the user's invitation when they join the event" do
      event = create(:event, is_private: true)
      invited_user = create(:user)
      invitation = create(:invitation, event: event, user: invited_user)
      create(:notification, user: invited_user, notifiable: event, kind: :invited)

      expect {
        create(:event_participant, user: invited_user, event: event, event_team: team_slot(event, "team_two"))
      }.to change { Invitation.exists?(invitation.id) }.from(true).to(false)

      expect(invited_user.notifications.invited.where(notifiable: event)).to exist
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

    it "rejects switching from one countable team to another when the target team is full" do
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

    it "allows the extra slot on team_two when number_of_participants is odd" do
      event = create(:event, number_of_participants: 11)
      team_one = team_slot(event, "team_one")
      team_two = team_slot(event, "team_two")

      4.times do
        create(:event_participant, user: create(:user), event: event, event_team: team_one)
      end
      5.times do
        create(:event_participant, user: create(:user), event: event, event_team: team_two)
      end

      expect(event.participants_count).to eq(10)
      expect(team_one.full?).to be(true)
      expect(team_two.full?).to be(false)

      extra_player = build(:event_participant, user: create(:user), event: event, event_team: team_two)
      expect(extra_player).to be_valid
    end

    it "rejects switching from the bench to a countable team when slots are full" do
      event = create(:event, number_of_participants: 2)
      create(:event_participant, user: create(:user), event: event, event_team: team_slot(event, "team_two"))
      participant = create(:event_participant, user: create(:user), event: event, event_team: team_slot(event, "bench"))

      expect(participant.update(event_team: team_slot(event, "team_one"))).to be(false)
      expect(participant.errors[:event_team]).to be_present
    end

    it "allows switching between countable teams when the target team has room" do
      event = create(:event, number_of_participants: 4)
      team_two_player = create(:user)
      create(:event_participant, user: team_two_player, event: event, event_team: team_slot(event, "team_two"))
      participant = event.event_participants.find_by!(user: event.user)

      expect(participant.update(event_team: team_slot(event, "team_two"))).to be(true)
    end

    it "rejects switching between countable teams when the target team is full" do
      event = create(:event, number_of_participants: 2)
      create(:event_participant, user: create(:user), event: event, event_team: team_slot(event, "team_two"))
      participant = event.event_participants.find_by!(user: event.user)

      expect(participant.update(event_team: team_slot(event, "team_two"))).to be(false)
      expect(participant.errors[:event_team]).to be_present
    end
  end

  describe "data side effects", :notification_jobs do
    it "does not notify anyone when the Event author self-registers" do
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

    it "always notifies when team_one has a custom label" do
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

    it "notifies remaining team and bench players when a player leaves team_one or team_two" do
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
      expect(bench_player.notifications.where(kind: :left).count).to eq(bench_player_count + 1)
      expect(player.notifications.where(kind: :left).count).to eq(leaving_player_count)
    end

    it "always notifies when leaving team_two with a custom label" do
      event = create(:event)
      team_slot(event, "team_two").update!(label: "Barcelona")
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

  describe "EventTeam change (update)", :notification_jobs do
    it "notifies countable players when a bench player joins a countable team" do
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

    it "notifies countable and bench players when a player moves from a countable team to the bench" do
      event = create(:event)
      team_player = create(:user)
      other_bench = create(:user)
      moving = create(:user)
      participant = create(:event_participant, user: moving, event: event, event_team: team_slot(event, "team_one"))

      create(:event_participant, user: team_player, event: event, event_team: team_slot(event, "team_two"))
      create(:event_participant, user: other_bench, event: event, event_team: team_slot(event, "bench"))

      expect {
        participant.update!(event_team: team_slot(event, "bench"))
      }.to change { event.user.notifications.where(kind: :left).count }.by(1)
        .and change { team_player.notifications.where(kind: :left).count }.by(1)
        .and change { other_bench.notifications.where(kind: :left).count }.by(1)
        .and change { Notification.where(kind: :joined).count }.by(0)
    end

    it "does not notify when a player moves from one countable team to another" do
      event = create(:event)
      team_player = create(:user)
      switching_player = create(:user)
      participant = create(:event_participant, user: switching_player, event: event, event_team: team_slot(event, "team_one"))

      create(:event_participant, user: team_player, event: event, event_team: team_slot(event, "team_two"))

      expect {
        participant.update!(event_team: team_slot(event, "team_two"))
      }.not_to change { Notification.count }
    end

    it "does not notify when a bench player stays on the bench" do
      event = create(:event)
      player = create(:user)
      participant = create(:event_participant, user: player, event: event, event_team: team_slot(event, "bench"))

      expect {
        participant.update!(event_team: team_slot(event, "bench"))
      }.not_to change { Notification.count }
    end
  end

  describe "batched notification delivery (insert_all)", :notification_jobs do
    it "inserts all joined notifications in a single Notification.insert_all call" do
      event = create(:event)
      team_player_one = create(:user)
      team_player_two = create(:user)
      create(:event_participant, user: team_player_one, event: event, event_team: team_slot(event, "team_one"))
      create(:event_participant, user: team_player_two, event: event, event_team: team_slot(event, "team_two"))
      joining_user = create(:user)
      inserted_rows = nil

      expect(Notification).to receive(:insert_all).once.and_wrap_original do |original, rows, **options|
        inserted_rows = rows
        original.call(rows, **options)
      end

      expect {
        create(:event_participant, user: joining_user, event: event, event_team: team_slot(event, "team_two"))
      }.to change { Notification.where(kind: :joined).count }.by(3)

      expect(inserted_rows.map { |row| row[:user_id] }).to contain_exactly(
        event.user.id, team_player_one.id, team_player_two.id
      )
      expect(inserted_rows.first[:notifiable_id]).to eq(event.id)
      expect(inserted_rows.first[:payload][:player]).to eq(joining_user.first_name)
    end

    it "does not call insert_all when there are no countable recipients" do
      event = create(:event)
      joining_user = create(:user)

      expect(Notification).not_to receive(:insert_all)

      create(:event_participant, user: joining_user, event: event, event_team: team_slot(event, "bench"))
    end
  end
end
