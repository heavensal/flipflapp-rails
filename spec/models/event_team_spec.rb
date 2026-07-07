require "rails_helper"

RSpec.describe EventTeam, type: :model do
  def team_slot(event, slot)
    event.event_teams.find_by!(slot: slot)
  end

  describe "validations" do
    it "requires a label" do
      team = build(:event_team, label: nil)
      expect(team).not_to be_valid
      expect(team.errors[:label]).to be_present
    end

    it "requires a slot" do
      team = build(:event_team, slot: nil)
      expect(team).not_to be_valid
      expect(team.errors[:slot]).to be_present
    end

    it "rejects an invalid slot value" do
      team = build(:event_team)
      expect { team.slot = "invalid" }.to raise_error(ArgumentError, /'invalid' is not a valid slot/)
    end

    it "rejects labels longer than 24 characters" do
      team = build(:event_team, label: "a" * 25)
      expect(team).not_to be_valid
      expect(team.errors[:label]).to be_present
    end

    it "accepts labels up to 24 characters with letters, digits, and spaces" do
      team = build(:event_team, label: "Real Madrid 2024")
      expect(team).to be_valid
    end

    it "accepts accented letters in labels" do
      team = build(:event_team, label: "Équipe des nuls")
      expect(team).to be_valid
    end

    it "rejects labels with punctuation or symbols" do
      team = build(:event_team, label: "Real-Madrid!")
      expect(team).not_to be_valid
      expect(team.errors[:label]).to be_present
    end

    it "rejects duplicate slots within the same event" do
      event = create(:event)
      duplicate = build(:event_team, event: event, slot: :team_one, label: "Another label")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:slot]).to be_present
    end

    it "rejects duplicate labels within the same event" do
      event = create(:event)
      existing_label = team_slot(event, "team_one").label
      duplicate = build(:event_team, event: event, slot: :bench, label: existing_label)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:label]).to be_present
    end

    it "rejects duplicate labels within the same event regardless of case" do
      event = create(:event)
      duplicate = build(:event_team, event: event, slot: :bench, label: team_slot(event, "team_one").label.swapcase)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:label]).to be_present
    end
  end

  describe "slot immutability" do
    it "does not allow changing slot after create" do
      event = create(:event)
      team = team_slot(event, "team_one")

      expect(team.update(slot: "bench")).to be(false)
      expect(team.reload.slot).to eq("team_one")
      expect(team.errors[:slot]).to be_present
    end
  end

  describe "bench label" do
    it "does not allow renaming the bench team" do
      event = create(:event)
      bench = team_slot(event, "bench")

      expect(bench.update(label: "Remplaçants")).to be(false)
      expect(bench.reload.label).to eq(I18n.t("event_team.slots.bench.default_label"))
      expect(bench.errors[:label]).to be_present
    end
  end

  describe ".countable_teams" do
    it "includes team_one and team_two for an event" do
      event = create(:event)

      expect(EventTeam.countable_teams.where(event: event).pluck(:slot)).to contain_exactly("team_one", "team_two")
    end

    it "excludes bench" do
      event = create(:event)

      expect(EventTeam.countable_teams.where(event: event)).not_to include(team_slot(event, "bench"))
    end
  end

  describe "#countable?" do
    it "is true for team_one and team_two" do
      event = create(:event)
      expect(team_slot(event, "team_one")).to be_countable
      expect(team_slot(event, "team_two")).to be_countable
    end

    it "is false for bench" do
      event = create(:event)
      expect(team_slot(event, "bench")).not_to be_countable
    end
  end
end
