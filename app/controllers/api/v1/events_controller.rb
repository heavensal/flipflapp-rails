# frozen_string_literal: true

module Api
  module V1
    class EventsController < BaseController
      before_action :set_event, only: %i[show update destroy]
      before_action :authorize_event_view!, only: %i[show update destroy]
      before_action :authorize_event_owner!, only: %i[update destroy]

      def index
        events = Event.visible_to(current_user)
                      .with_countable_participants_count
                      .upcoming
                      .includes(:user)
        render json: EventSerializer.new(events, params: { current_user: current_user }).serializable_hash
      end

      def show
        render json: EventSerializer.new(@event, params: { current_user: current_user }).serializable_hash
      end

      def create
        event = current_user.events.build(event_params)
        if event.save
          render json: EventSerializer.new(event, params: { current_user: current_user }).serializable_hash,
                 status: :created
        else
          render_validation_errors(event)
        end
      end

      def update
        if @event.update(event_params)
          render json: EventSerializer.new(@event, params: { current_user: current_user }).serializable_hash
        else
          render_validation_errors(@event)
        end
      end

      def destroy
        @event.destroy!
        head :no_content
      end

      private

      def set_event
        @event = Event.find(params[:id])
      end

      def authorize_event_view!
        render_not_found unless @event.viewable_by?(current_user)
      end

      def authorize_event_owner!
        render_forbidden unless @event.am_i_the_author?(current_user)
      end

      def event_params
        params.require(:event).permit(
          :title, :description, :location, :start_time, :number_of_participants,
          :price, :is_private, :latitude, :longitude
        )
      end
    end
  end
end
