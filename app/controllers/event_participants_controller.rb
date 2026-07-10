class EventParticipantsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event, except: :destroy

  def create
    unless @event.joinable_by?(current_user)
      redirect_to authenticated_root_path, alert: t("events.authorization.inaccessible") and return
    end

    event_participant = @event.event_participants.find_or_initialize_by(user: current_user)
    event_team = @event.event_teams.find_by(id: event_participant_params[:event_team_id])
    unless event_team
      redirect_to @event, alert: t("events.teams.not_found") and return
    end

    event_participant.assign_attributes(event_team: event_team)
    if event_participant.save
      redirect_to @event, notice: t("event_participants.create.success", label: event_participant.event_team.label)
    else
      redirect_to @event, alert: event_participant.errors.full_messages.to_sentence
    end
  end

  def destroy
    @event_participant = current_user.event_participants.find_by(id: params[:id])
    if @event_participant.nil?
      redirect_to authenticated_root_path, alert: t("event_participants.destroy.not_found") and return
    end

    @event = @event_participant.event

    if @event_participant.destroy
      redirect_path = @event.viewable_by?(current_user) ? @event : authenticated_root_path
      redirect_to redirect_path, alert: t("event_participants.destroy.success")
    else
      redirect_to @event, alert: t("event_participants.destroy.failure")
    end
  end

  private

  def event_participant_params
    params.require(:event_participant).permit(:event_team_id)
  end

  def set_event
    @event = Event.find(params[:event_id])
  end
end
