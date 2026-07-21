# frozen_string_literal: true

module Api
  module V1
    class EventParticipantsController < BaseController
      before_action :set_event, except: :destroy

      def index
        scope = @event.event_participants.includes(:user)
        if params[:event_team_id].present?
          scope = scope.where(event_team_id: params[:event_team_id])
        end
        render json: EventParticipantSerializer.new(scope).serializable_hash
      end

      def create
        unless @event.joinable_by?(current_user)
          return render_not_found
        end

        event_participant = @event.event_participants.find_or_initialize_by(user: current_user)
        event_team = @event.event_teams.find_by(id: event_participant_params[:event_team_id])
        return render_not_found unless event_team

        event_participant.assign_attributes(event_team: event_team)
        if event_participant.save
          render json: EventParticipantSerializer.new(event_participant).serializable_hash,
                 status: event_participant.previously_new_record? ? :created : :ok
        else
          render_validation_errors(event_participant)
        end
      end

      def destroy
        event_participant = current_user.event_participants.find_by(id: params[:id])
        return render_not_found unless event_participant

        event_participant.destroy!
        head :no_content
      end

      private

      def set_event
        @event = Event.find(params[:event_id])
        render_not_found unless @event.viewable_by?(current_user)
      end

      def event_participant_params
        params.require(:event_participant).permit(:event_team_id)
      end
    end
  end
end
