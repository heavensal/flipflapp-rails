class Event < ApplicationRecord
  belongs_to :user
  has_many :event_teams, dependent: :destroy
  has_many :event_participants, dependent: :destroy

  validates :title, presence: true
  validates :location, presence: true
  validates :start_time, presence: true
  validate :start_time_must_be_in_the_future
  validates :number_of_participants, numericality: { only_integer: true, greater_than: 0 }
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :is_private, inclusion: { in: [ true, false ] }

  # trier auto par date les plus proches
  scope :upcoming, -> { where("start_time > ?", Time.current).order(:start_time) }

  after_create :set_teams_and_author

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
end
