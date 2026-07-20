# frozen_string_literal: true

class Events::InvitationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event

  def create
    unless @event.can_invite?(current_user)
      redirect_to authenticated_root_path, alert: t("events.flash.authorization.invitation_required") and return
    end

    user_ids = Array(params[:user_ids]).reject(&:blank?)
    if user_ids.empty?
      redirect_to @event, alert: t("events.flash.invitations.create.empty") and return
    end

    invited_friends = current_user.get_my_friends_but_not_participants(@event).where(id: user_ids)
    if invited_friends.empty?
      redirect_to @event, alert: t("events.flash.invitations.create.empty") and return
    end

    @event.invite!(users: invited_friends, sender: current_user)

    redirect_to @event, notice: t("events.flash.invitations.create.success")
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end
end
