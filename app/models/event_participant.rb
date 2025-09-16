class EventParticipant < ApplicationRecord
  belongs_to :user
  belongs_to :event
  belongs_to :event_team

  validates :user_id, uniqueness: { scope: [ :event_id ], message: "est déjà inscrit à cet événement" }

  after_create :notify_joining
  after_destroy :notify_leaving

  def notify_joining
    # Notifier l'auteur de l'événement qu'un nouveau joueur a rejoint
    Notification.create!(
      user: self.event.user,
      notifiable: self.event,
      kind: :joined,
      payload: {
        title: self.event.title,
        start_time: self.event.start_time,
        player: self.user.first_name
      }
    )
  end

  def notify_leaving
    # Notifier l'auteur de l'événement qu'un joueur a quitté
    Notification.create!(
      user: self.event.user,
      notifiable: self.event,
      kind: :left,
      payload: {
        title: self.event.title,
        start_time: self.event.start_time,
        player: self.user.first_name
      }
    )
  end


end
