require "rails_helper"

RSpec.describe "EventParticipants", type: :request do
  def team_slot(event, slot)
    event.event_teams.find_by!(slot: slot)
  end

  describe "POST /events/:event_id/event_participants" do
    it "creates a participant on a countable team with available capacity" do
      event = create(:event, is_private: false)
      user = create(:user)
      team = team_slot(event, "team_two")
      sign_in user

      expect {
        post event_event_participants_path(event), params: { event_participant: { event_team_id: team.id } }
      }.to change { event.event_participants.where(user: user).count }.from(0).to(1)

      expect(event.event_participants.find_by(user: user).event_team).to eq(team)
    end

    it "destroys the invitation when an invited user joins" do
      event = create(:event, is_private: true)
      user = create(:user)
      create(:invitation, event: event, user: user)
      team = team_slot(event, "team_two")
      sign_in user

      expect {
        post event_event_participants_path(event), params: { event_participant: { event_team_id: team.id } }
      }.to change { event.invitations.where(user: user).count }.from(1).to(0)
    end

    it "creates a participant on the bench when countable slots are full" do
      event = create(:event, number_of_participants: 2, is_private: false)
      create(:event_participant, user: create(:user), event: event, event_team: team_slot(event, "team_two"))
      user = create(:user)
      bench = team_slot(event, "bench")
      sign_in user

      expect {
        post event_event_participants_path(event), params: { event_participant: { event_team_id: bench.id } }
      }.to change { event.event_participants.where(user: user).count }.from(0).to(1)

      expect(event.event_participants.find_by(user: user).event_team).to eq(bench)
    end

    it "rejects joining a full countable team" do
      event = create(:event, number_of_participants: 10, is_private: false)
      team_one = team_slot(event, "team_one")
      4.times do
        create(:event_participant, user: create(:user), event: event, event_team: team_one)
      end
      user = create(:user)
      sign_in user

      expect {
        post event_event_participants_path(event), params: { event_participant: { event_team_id: team_one.id } }
      }.not_to change(EventParticipant, :count)
    end

    it "rejects switching to a full countable team" do
      event = create(:event, number_of_participants: 10, is_private: false)
      team_one = team_slot(event, "team_one")
      team_two = team_slot(event, "team_two")
      4.times do
        create(:event_participant, user: create(:user), event: event, event_team: team_one)
      end
      switcher = create(:user)
      participant = create(:event_participant, user: switcher, event: event, event_team: team_two)
      sign_in switcher

      expect {
        post event_event_participants_path(event), params: { event_participant: { event_team_id: team_one.id } }
      }.not_to change { participant.reload.event_team_id }
    end

    it "rejects joining a countable team when all official slots are taken" do
      event = create(:event, number_of_participants: 2, is_private: false)
      create(:event_participant, user: create(:user), event: event, event_team: team_slot(event, "team_two"))
      user = create(:user)
      sign_in user

      expect {
        post event_event_participants_path(event), params: { event_participant: { event_team_id: team_slot(event, "team_one").id } }
      }.not_to change(EventParticipant, :count)
    end

    it "accepts the extra slot on team_two for an odd number_of_participants" do
      event = create(:event, number_of_participants: 11, is_private: false)
      team_one = team_slot(event, "team_one")
      team_two = team_slot(event, "team_two")
      4.times { create(:event_participant, user: create(:user), event: event, event_team: team_one) }
      5.times { create(:event_participant, user: create(:user), event: event, event_team: team_two) }
      user = create(:user)
      sign_in user

      expect {
        post event_event_participants_path(event), params: { event_participant: { event_team_id: team_two.id } }
      }.to change { team_two.reload.event_participants.count }.from(5).to(6)
    end

    it "rejects joining team_two when its extra slot is already taken" do
      event = create(:event, number_of_participants: 11, is_private: false)
      team_two = team_slot(event, "team_two")
      4.times { create(:event_participant, user: create(:user), event: event, event_team: team_slot(event, "team_one")) }
      6.times { create(:event_participant, user: create(:user), event: event, event_team: team_two) }
      user = create(:user)
      sign_in user

      expect {
        post event_event_participants_path(event), params: { event_participant: { event_team_id: team_two.id } }
      }.not_to change(EventParticipant, :count)
    end

    it "does not create a participant when the event_team_id is invalid" do
      event = create(:event, is_private: false)
      user = create(:user)
      sign_in user

      expect {
        post event_event_participants_path(event), params: { event_participant: { event_team_id: 999_999 } }
      }.not_to change(EventParticipant, :count)
    end

    it "does not create a participant on a private event for an unauthorized user" do
      event = create(:event, is_private: true)
      user = create(:user)
      sign_in user

      expect {
        post event_event_participants_path(event), params: { event_participant: { event_team_id: team_slot(event, "team_one").id } }
      }.not_to change(EventParticipant, :count)
    end
  end

  describe "DELETE /event_participants/:id" do
    it "destroys the participant record" do
      event = create(:event, is_private: false)
      user = create(:user)
      participant = create(:event_participant, user: user, event: event, event_team: team_slot(event, "team_two"))
      sign_in user

      expect {
        delete event_participant_path(participant)
      }.to change(EventParticipant, :count).by(-1)
    end

    it "does not destroy anything when the participant does not belong to the signed-in user" do
      user = create(:user)
      sign_in user

      expect {
        delete event_participant_path(999_999)
      }.not_to change(EventParticipant, :count)
    end
  end
end
