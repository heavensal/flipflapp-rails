require "rails_helper"

# Spécifications des messages flash (notice / alert) émis par
# EventParticipantsController lors de l'inscription (create) et de la
# désinscription (destroy) d'un utilisateur à un événement.
#
# On vérifie que chaque flash provient d'une clé I18n (et non d'une chaîne
# codée en dur), y compris les erreurs de capacité remontées par le modèle
# EventParticipant (team_full, countable_full).
RSpec.describe "Messages flash d'EventParticipantsController", type: :request do
  def team_slot(event, slot)
    event.event_teams.find_by!(slot: slot)
  end

  describe "POST /events/:event_id/event_participants (rejoindre / changer d'équipe)" do
    context "quand un utilisateur rejoint une équipe countable qui a de la place" do
      it "affiche un flash notice avec la clé event_participants.create.success et le nom de l'équipe" do
        event = create(:event, is_private: false)
        user = create(:user)
        sign_in user
        team = team_slot(event, "team_two")

        post event_event_participants_path(event), params: { event_participant: { event_team_id: team.id } }

        expect(response).to redirect_to(event_path(event))
        expect(flash[:notice]).to eq(I18n.t("event_participants.create.success", label: team.label))
      end
    end

    context "quand un utilisateur rejoint le banc d'un événement complet" do
      it "affiche un flash notice avec la clé event_participants.create.success" do
        event = create(:event, number_of_participants: 2, is_private: false)
        create(:event_participant, user: create(:user), event: event, event_team: team_slot(event, "team_two"))
        user = create(:user)
        sign_in user
        bench = team_slot(event, "bench")

        post event_event_participants_path(event), params: { event_participant: { event_team_id: bench.id } }

        expect(response).to redirect_to(event_path(event))
        expect(flash[:notice]).to eq(I18n.t("event_participants.create.success", label: bench.label))
      end
    end

    context "quand l'équipe countable visée est complète (erreur team_full)" do
      it "affiche un flash alert avec la clé activerecord.errors...event_team.team_full" do
        event = create(:event, number_of_participants: 10, is_private: false)
        team_one = team_slot(event, "team_one")
        4.times do
          create(:event_participant, user: create(:user), event: event, event_team: team_one)
        end

        user = create(:user)
        sign_in user

        post event_event_participants_path(event), params: { event_participant: { event_team_id: team_one.id } }

        expect(response).to redirect_to(event_path(event))
        expected = I18n.t("activerecord.errors.models.event_participant.attributes.event_team.team_full")
        expect(flash[:alert]).to include(expected)
      end
    end

    context "quand un participant déjà inscrit change d'équipe countable vers une équipe pleine" do
      it "affiche un flash alert avec l'erreur team_full" do
        event = create(:event, number_of_participants: 10, is_private: false)
        team_one = team_slot(event, "team_one")
        team_two = team_slot(event, "team_two")
        4.times do
          create(:event_participant, user: create(:user), event: event, event_team: team_one)
        end

        switcher = create(:user)
        create(:event_participant, user: switcher, event: event, event_team: team_two)
        sign_in switcher

        post event_event_participants_path(event), params: { event_participant: { event_team_id: team_one.id } }

        expect(response).to redirect_to(event_path(event))
        expected = I18n.t("activerecord.errors.models.event_participant.attributes.event_team.team_full")
        expect(flash[:alert]).to include(expected)
      end
    end

    context "quand toutes les places officielles sont prises" do
      it "refuse un POST vers une équipe pleine avec l'erreur team_full" do
        event = create(:event, number_of_participants: 2, is_private: false)
        create(:event_participant, user: create(:user), event: event, event_team: team_slot(event, "team_two"))
        user = create(:user)
        sign_in user

        post event_event_participants_path(event), params: { event_participant: { event_team_id: team_slot(event, "team_one").id } }

        expect(response).to redirect_to(event_path(event))
        expected = I18n.t("activerecord.errors.models.event_participant.attributes.event_team.team_full")
        expect(flash[:alert]).to include(expected)
      end
    end

    context "quand team_two a une place de plus sur un effectif impair (11 = 5 vs 6)" do
      it "accepte le 6e joueur sur team_two via POST" do
        event = create(:event, number_of_participants: 11, is_private: false)
        team_one = team_slot(event, "team_one")
        team_two = team_slot(event, "team_two")

        4.times do
          create(:event_participant, user: create(:user), event: event, event_team: team_one)
        end
        5.times do
          create(:event_participant, user: create(:user), event: event, event_team: team_two)
        end

        user = create(:user)
        sign_in user

        post event_event_participants_path(event), params: { event_participant: { event_team_id: team_two.id } }

        expect(response).to redirect_to(event_path(event))
        expect(flash[:notice]).to eq(I18n.t("event_participants.create.success", label: team_two.label))
        expect(team_two.reload.event_participants.count).to eq(6)
      end

      it "refuse le 7e joueur sur team_two même via POST direct" do
        event = create(:event, number_of_participants: 11, is_private: false)
        team_two = team_slot(event, "team_two")

        4.times do
          create(:event_participant, user: create(:user), event: event, event_team: team_slot(event, "team_one"))
        end
        6.times do
          create(:event_participant, user: create(:user), event: event, event_team: team_two)
        end

        user = create(:user)
        sign_in user

        post event_event_participants_path(event), params: { event_participant: { event_team_id: team_two.id } }

        expect(response).to redirect_to(event_path(event))
        expected = I18n.t("activerecord.errors.models.event_participant.attributes.event_team.team_full")
        expect(flash[:alert]).to include(expected)
      end
    end

    context "quand l'event_team_id fourni n'existe pas sur l'événement" do
      it "affiche un flash alert avec la clé events.teams.not_found" do
        event = create(:event, is_private: false)
        user = create(:user)
        sign_in user

        post event_event_participants_path(event), params: { event_participant: { event_team_id: 999_999 } }

        expect(response).to redirect_to(event_path(event))
        expect(flash[:alert]).to eq(I18n.t("events.teams.not_found"))
      end
    end

    context "quand un utilisateur non autorisé tente de rejoindre un événement privé" do
      it "affiche un flash alert avec la clé events.authorization.inaccessible" do
        event = create(:event, is_private: true)
        user = create(:user)
        sign_in user

        post event_event_participants_path(event), params: { event_participant: { event_team_id: team_slot(event, "team_one").id } }

        expect(response).to redirect_to(authenticated_root_path)
        expect(flash[:alert]).to eq(I18n.t("events.authorization.inaccessible"))
      end
    end
  end

  describe "DELETE /event_participants/:id (quitter l'événement)" do
    context "quand l'utilisateur quitte un événement qu'il peut toujours voir" do
      it "affiche un flash alert avec la clé event_participants.destroy.success" do
        event = create(:event, is_private: false)
        user = create(:user)
        participant = create(:event_participant, user: user, event: event, event_team: team_slot(event, "team_two"))
        sign_in user

        delete event_participant_path(participant)

        expect(response).to redirect_to(event_path(event))
        expect(flash[:alert]).to eq(I18n.t("event_participants.destroy.success"))
      end
    end

    context "quand le participant n'existe pas pour l'utilisateur connecté" do
      it "affiche un flash alert avec la clé event_participants.destroy.not_found" do
        user = create(:user)
        sign_in user

        delete event_participant_path(999_999)

        expect(response).to redirect_to(authenticated_root_path)
        expect(flash[:alert]).to eq(I18n.t("event_participants.destroy.not_found"))
      end
    end
  end
end
