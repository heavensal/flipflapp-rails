# frozen_string_literal: true

module Api
  module V1
    class EventTeamsController < BaseController
      before_action :set_event
      before_action :set_event_team, only: %i[show update]
      before_action :authorize_participant!, only: :update
      before_action :authorize_countable_team!, only: :update

      def index
        event_teams = @event.event_teams.order(:slot)
        render json: EventTeamSerializer.new(event_teams).serializable_hash
      end

      def show
        render json: EventTeamSerializer.new(@event_team).serializable_hash
      end

      def update
        if @event_team.update(event_team_params)
          render json: EventTeamSerializer.new(@event_team).serializable_hash
        else
          render_validation_errors(@event_team)
        end
      end

      private

      def set_event
        @event = Event.find(params[:event_id])
        render_not_found unless @event.viewable_by?(current_user)
      end

      def set_event_team
        @event_team = @event.event_teams.find(params[:id])
      end

      def authorize_participant!
        render_forbidden unless @event.in_this_event?(current_user)
      end

      def authorize_countable_team!
        render_forbidden unless @event_team.countable?
      end

      def event_team_params
        params.require(:event_team).permit(:label)
      end
    end
  end
end
