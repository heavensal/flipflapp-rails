require "rails_helper"

# Spécifications des messages flash (notice / alert) émis par
# EventTeamsController lors du renommage d'une équipe (update).
#
# On vérifie que chaque flash provient d'une clé I18n : succès, autorisations
# (participant_required, bench_not_renamable) et erreurs de validation du
# modèle EventTeam (label invalide).
RSpec.describe "Messages flash de renommage d'EventTeamsController", type: :request do
  def team_slot(event, slot)
    event.event_teams.find_by!(slot: slot)
  end

  describe "PATCH /events/:event_id/event_teams/:id (renommer le label)" do
    context "quand un participant renomme une équipe countable avec un label valide" do
      it "affiche un flash notice avec la clé event_team.update.success" do
        event = create(:event, is_private: false)
        participant = create(:user)
        create(:event_participant, user: participant, event: event, event_team: team_slot(event, "team_two"))
        sign_in participant
        team = team_slot(event, "team_one")

        patch event_event_team_path(event, team), params: { event_team: { label: "Barcelone" } }

        expect(response).to redirect_to(event_path(event))
        expect(flash[:notice]).to eq(I18n.t("event_team.update.success"))
      end
    end

    context "quand un utilisateur non participant tente de renommer une équipe" do
      it "affiche un flash alert avec la clé event_team.authorization.participant_required" do
        event = create(:event, is_private: false)
        outsider = create(:user)
        sign_in outsider
        team = team_slot(event, "team_one")

        patch event_event_team_path(event, team), params: { event_team: { label: "Barcelone" } }

        expect(response).to redirect_to(event_path(event))
        expect(flash[:alert]).to eq(I18n.t("event_team.authorization.participant_required"))
      end
    end

    context "quand on tente de renommer le banc" do
      it "affiche un flash alert avec la clé event_team.authorization.bench_not_renamable" do
        event = create(:event, is_private: false)
        participant = create(:user)
        create(:event_participant, user: participant, event: event, event_team: team_slot(event, "team_one"))
        sign_in participant
        bench = team_slot(event, "bench")

        patch event_event_team_path(event, bench), params: { event_team: { label: "Remplaçants" } }

        expect(response).to redirect_to(event_path(event))
        expect(flash[:alert]).to eq(I18n.t("event_team.authorization.bench_not_renamable"))
      end
    end

    context "quand le label proposé contient des caractères interdits" do
      it "affiche un flash alert avec les erreurs du modèle EventTeam et ne modifie pas le label" do
        event = create(:event, is_private: false)
        participant = create(:user)
        create(:event_participant, user: participant, event: event, event_team: team_slot(event, "team_two"))
        sign_in participant
        team = team_slot(event, "team_one")

        patch event_event_team_path(event, team), params: { event_team: { label: "Real-Madrid!" } }

        expect(response).to redirect_to(event_path(event))
        expect(flash[:alert]).to be_present
        expect(flash[:alert]).to include(EventTeam.human_attribute_name(:label))
        expect(team.reload.label).not_to eq("Real-Madrid!")
      end
    end
  end
end
