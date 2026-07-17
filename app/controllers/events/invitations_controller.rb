# frozen_string_literal: true

class Events::InvitationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event

  def create
    unless @event.can_invite?(current_user)
      redirect_to authenticated_root_path, alert: t("events.authorization.invitation_required") and return
    end

    invited_friends = current_user.get_my_friends_but_not_participants(@event).where(id: params[:user_ids] || [])

    @event.invite!(users: invited_friends, sender: current_user)

    redirect_to @event, notice: t("events.invitations.create.success")
  rescue StandardError => e
    Rails.logger.error("Invitation error: #{e.message}")
    redirect_to @event, alert: t("events.invitations.create.failure")
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end
end
