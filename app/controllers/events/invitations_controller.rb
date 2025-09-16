class Events::InvitationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event

  def create
    invited_friends = User.where(id: params[:user_ids] || [])

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

    redirect_to @event, notice: "Invitations envoyées avec succès."
  rescue StandardError => e
    Rails.logger.error("Erreur invitation: #{e.message}")
    redirect_to @event, alert: "Une erreur est survenue lors de l'envoi des invitations."
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end
end
