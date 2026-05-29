require "rails_helper"

RSpec.describe EventTeam, type: :model do
  describe "validations" do
    it "requires a name" do
      team = build(:event_team, name: nil)
      expect(team).not_to be_valid
      expect(team.errors[:name]).to be_present
    end

    it "rejects duplicate team names within the same event" do
      event = create(:event)
      duplicate = build(:event_team, event: event, name: event.event_teams.first.name)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to be_present
    end
  end
end
