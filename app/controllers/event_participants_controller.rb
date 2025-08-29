class EventParticipantsController < ApplicationController
  before_action :authenticate_user!

  def create
    @event = Event.find(params[:event_id])
    event_participant = @event.event_participants.find_or_initialize_by(user: current_user)
    event_participant.assign_attributes(event_participant_params)
    if event_participant.save
      redirect_to @event, notice: "Vous participez maintenant à cet événement."
    else
      flash.now[:alert] = "Une erreur est survenue lors de votre inscription."
      render @event, status: :unprocessable_entity
    end
  end

  def destroy
    @event = Event.find(params[:event_id])
    event_participant = @event.event_participants.find_by(user: current_user)

    if event_participant&.destroy
      redirect_to @event, notice: "Vous avez quitté cet événement."
    else
      flash.now[:alert] = "Une erreur est survenue lors de votre désinscription."
      render @event, status: :unprocessable_entity
    end
  end

  private

  def event_participant_params
    params.require(:event_participant).permit(:event_team_id)
  end
end
