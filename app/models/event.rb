class Event < ApplicationRecord
  TRACKED_NOTIFICATION_FIELDS = %w[title start_time price number_of_participants].freeze
  TEAM_SLOTS = %w[team_one team_two bench].freeze
  SLOT_DEFAULT_LABEL_KEYS = TEAM_SLOTS.index_with { |slot| "event_team.slots.#{slot}.default_label" }.freeze

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

  scope :upcoming, -> { where("start_time > ?", Time.current).order(:start_time) }

  after_create_commit :set_teams_and_author
  after_update_commit :notify_update
  before_destroy :prepare_cancellation_notifications, prepend: true
  after_destroy_commit :notify_cancellation

  def self.default_label_for(slot)
    I18n.t(SLOT_DEFAULT_LABEL_KEYS.fetch(slot.to_s))
  end

  def self.visible_to(user)
    return none if user.blank?

    participant_event_ids = EventParticipant.where(user: user).select(:event_id)
    invited_event_ids = Notification.invited.where(user: user, notifiable_type: name).select(:notifiable_id)

    where(is_private: false)
      .or(where(user_id: user.id))
      .or(where(id: participant_event_ids))
      .or(where(id: invited_event_ids))
      .distinct
  end

  def set_teams_and_author
    TEAM_SLOTS.each do |slot|
      event_teams.create!(slot: slot, label: self.class.default_label_for(slot))
    end
    event_participants.create!(user: user, event_team: event_teams.find_by!(slot: :team_one))
  end

  def start_time_must_be_in_the_future
    return if start_time.blank?
    if start_time < Time.current
      errors.add(:start_time, "L'heure de début ne peut pas être déjà passée.")
    end
  end

  def participants_count
    event_participants.joins(:event_team).merge(EventTeam.countable_teams).count
  end

  def registrations_count
    event_participants.count
  end

  def countable_slots_full?
    participants_count >= number_of_participants
  end

  def countable_slots_per_team
    number_of_participants / 2
  end

  def countable_slots_for(team)
    return 0 unless team.countable?

    if team.team_one?
      number_of_participants / 2
    else
      (number_of_participants + 1) / 2
    end
  end

  def am_i_the_author?(user)
    self.user == user
  end

  def in_this_event?(user)
    event_participants.exists?(user: user)
  end

  def can_invite?(user)
    in_this_event?(user)
  end

  def viewable_by?(user)
    return false if user.blank?

    !is_private || am_i_the_author?(user) || in_this_event?(user) || invited?(user)
  end

  def joinable_by?(user)
    viewable_by?(user)
  end

  def invited?(user)
    notifications.invited.exists?(user: user)
  end

  ######################################## NOTIFICATIONS ##########################
  def prepare_cancellation_notifications
    @cancellation_notification_user_ids = event_participants.where.not(user_id: user_id).distinct.pluck(:user_id)
    @cancellation_notification_payload = {
      title: title,
      start_time: start_time,
      author: user.first_name
    }
  end

  def notify_cancellation
    Notification.where(notifiable_type: self.class.name, notifiable_id: id).delete_all

    Array(@cancellation_notification_user_ids).each do |player_id|
      Notification.create!(
        user_id: player_id,
        notifiable: nil,
        kind: :canceled,
        payload: @cancellation_notification_payload
      )
    end
  end

  def notify_update
    tracked_changes = saved_changes.slice(*TRACKED_NOTIFICATION_FIELDS)
    return if tracked_changes.empty?

    players.where.not(id: user_id).find_each do |player|
      tracked_changes.each do |field, (old_value, new_value)|
        Notification.create!(
          user: player,
          notifiable: self,
          kind: :updated,
          payload: {
            actor: user.first_name,
            field: field,
            title: notification_event_title(field, old_value),
            start_time: start_time,
            old_value: notification_payload_value(field, old_value),
            new_value: notification_payload_value(field, new_value)
          }
        )
      end
    end
  end

  def notification_payload_value(field, value)
    case field
    when "price"
      format("%.2f", value.to_f)
    when "start_time"
      value&.iso8601
    else
      value
    end
  end

  def notification_event_title(field, old_value)
    field == "title" ? old_value : title
  end
end
