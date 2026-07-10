require "rails_helper"

RSpec.describe "EventTeams", type: :request do
  def team_slot(event, slot)
    event.event_teams.find_by!(slot: slot)
  end

  describe "PATCH /events/:event_id/event_teams/:id" do
    it "updates the label when a participant renames a countable team" do
      event = create(:event, is_private: false)
      participant = create(:user)
      create(:event_participant, user: participant, event: event, event_team: team_slot(event, "team_two"))
      team = team_slot(event, "team_one")
      sign_in participant

      patch event_event_team_path(event, team), params: { event_team: { label: "Barcelona" } }

      expect(team.reload.label).to eq("Barcelona")
    end

    it "does not update the label when the user is not a participant" do
      event = create(:event, is_private: false)
      outsider = create(:user)
      team = team_slot(event, "team_one")
      original_label = team.label
      sign_in outsider

      patch event_event_team_path(event, team), params: { event_team: { label: "Barcelona" } }

      expect(team.reload.label).to eq(original_label)
    end

    it "does not update the bench label" do
      event = create(:event, is_private: false)
      participant = create(:user)
      create(:event_participant, user: participant, event: event, event_team: team_slot(event, "team_one"))
      bench = team_slot(event, "bench")
      original_label = bench.label
      sign_in participant

      patch event_event_team_path(event, bench), params: { event_team: { label: "Substitutes" } }

      expect(bench.reload.label).to eq(original_label)
    end

    it "does not update the label when validation fails" do
      event = create(:event, is_private: false)
      participant = create(:user)
      create(:event_participant, user: participant, event: event, event_team: team_slot(event, "team_two"))
      team = team_slot(event, "team_one")
      original_label = team.label
      sign_in participant

      patch event_event_team_path(event, team), params: { event_team: { label: "Real-Madrid!" } }

      expect(team.reload.label).to eq(original_label)
    end
  end
end
