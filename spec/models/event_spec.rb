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
end
