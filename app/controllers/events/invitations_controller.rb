class Events::InvitationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event

  def create
    unless @event.can_invite?(current_user)
      redirect_to authenticated_root_path, alert: t("events.authorization.invitation_required") and return
    end

    invited_friends = current_user.get_my_friends_but_not_participants(@event).where(id: params[:user_ids] || [])

    Notification.transaction do
      invited_friends.find_each do |friend|
        Notification.create!(
          user: friend,
          notifiable: @event,
          kind: :invited,
          payload: {
            title: @event.title,
            start_time: @event.start_time,
            sender: current_user.first_name
          }
        )
      end
    end

    redirect_to @event, notice: t("events.invitations.create.success")
  rescue StandardError => e
    Rails.logger.error("Erreur invitation: #{e.message}")
    redirect_to @event, alert: t("events.invitations.create.failure")
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end
end
