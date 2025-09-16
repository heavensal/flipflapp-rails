class Event < ApplicationRecord
  belongs_to :user
  has_many :event_teams, dependent: :destroy
  has_many :event_participants, dependent: :destroy
  has_many :players, through: :event_participants, source: :user
  has_many :notifications, as: :notifiable

  validates :title, presence: true
  validates :location, presence: true
  validates :start_time, presence: true
  validate :start_time_must_be_in_the_future
  validates :number_of_participants, numericality: { only_integer: true, greater_than: 0 }
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :is_private, inclusion: { in: [ true, false ] }

  # trier auto par date les plus proches
  scope :upcoming, -> { where("start_time > ?", Time.current).order(:start_time) }

  after_create_commit :set_teams_and_author
  after_update_commit :notify_update
  after_destroy_commit :notify_cancellation

  def set_teams_and_author
    self.event_teams.create(name: "Equipe 1")
    self.event_teams.create(name: "Equipe 2")
    self.event_teams.create(name: "Sur le Banc")
    self.event_participants.create(user: self.user, event_team: self.event_teams.first)
  end

  def start_time_must_be_in_the_future
    return if start_time.blank?
    if start_time < Time.current
      errors.add(:start_time, "L'heure de début ne peut pas être déjà passée.")
    end
  end

  def participants_count
    event_participants.joins(:event_team).where.not(event_teams: { name: "Sur le Banc" }).count
  end

  def am_i_the_author?(user)
    self.user == user
  end

  def in_this_event?(user)
    event_participants.exists?(user: user)
  end

  ######################################## NOTIFICATIONS ##########################
  def notify_cancellation
    # Notifier tous les joueurs que l'événement a été annulé
    self.players.where.not(id: self.user.id).each do |player|
      Notification.create!(
        user: player,
        notifiable: nil,
        kind: :canceled,
        payload: {
          title: self.title,
          start_time: self.start_time,
          author: self.user.first_name
        }
      )
    end

    # Supprimer les notifications autres que "canceled" liées à cet événement
    self.notifications.where.not(kind: :canceled).delete_all
  end

  def notify_update
    # on cible ces colonnes qui changent
    changes_to_track = %w[title location start_time price number_of_participants]
    return if (self.saved_changes.keys & changes_to_track).empty?

    # il y a eu des changements sur les colonnes trackées ?
    if (self.saved_changes.keys & changes_to_track).any?
      # Notifier tous les joueurs que l'événement a été mis à jour
      self.players.where.not(id: self.user.id).each do |player|
        Notification.create!(
          user: player,
          notifiable: self,
          kind: :updated,
          payload: {
            title: self.title,
            start_time: self.start_time,
            location: self.location,
            price: self.price,
            number_of_participants: self.number_of_participants,
            changes: self.saved_changes.slice(*changes_to_track)
          }
        )
      end
    end
  end
end
