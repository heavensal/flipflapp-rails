require "rails_helper"

RSpec.describe EventParticipant, type: :model do
  describe "validations" do
    it "rejects duplicate registration for the same event" do
      event = create(:event)
      player = create(:user)
      create(:event_participant, user: player, event: event)

      duplicate = build(:event_participant, user: player, event: event, event_team: event.event_teams.second)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to be_present
    end
  end

  describe "data side effects" do
    it "notifies the event author when a player joins" do
      event = create(:event)
      player = create(:user)

      expect {
        create(:event_participant, user: player, event: event)
      }.to change { event.user.notifications.where(kind: :joined).count }.by(1)
    end

    it "notifies the event author when a player leaves" do
      event = create(:event)
      player = create(:user)
      participant = create(:event_participant, user: player, event: event)

      expect {
        participant.destroy!
      }.to change { event.user.notifications.where(kind: :left).count }.by(1)
    end
  end
end
