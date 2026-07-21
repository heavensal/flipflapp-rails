# frozen_string_literal: true

module Api
  module V1
    module Events
      class InvitationsController < BaseController
        before_action :set_event

        def index
          invitations = @event.invitations.includes(:user).order(:created_at)
          render json: InvitationSerializer.new(invitations).serializable_hash
        end

        def create
          unless @event.can_invite?(current_user)
            return render_forbidden
          end

          user_ids = Array(params[:user_ids]).reject(&:blank?)
          if user_ids.empty?
            return render_error("No users to invite", :unprocessable_entity)
          end

          invited_friends = current_user.get_my_friends_but_not_participants(@event).where(id: user_ids)
          if invited_friends.empty?
            return render_error("No users to invite", :unprocessable_entity)
          end

          @event.invite!(users: invited_friends, sender: current_user)
          invitations = @event.invitations.where(user: invited_friends).includes(:user)
          render json: InvitationSerializer.new(invitations).serializable_hash, status: :created
        end

        private

        def set_event
          @event = Event.find(params[:event_id])
          render_not_found unless @event.viewable_by?(current_user)
        end
      end
    end
  end
end
