class Event < ApplicationRecord
  include Event::Notifications
  include Event::BenchReminder

  TEAM_SLOTS = %w[team_one team_two bench].freeze
  SLOT_DEFAULT_LABEL_KEYS = TEAM_SLOTS.index_with { |slot| "event_team.slots.#{slot}.default_label" }.freeze
  COUNTABLE_PARTICIPANTS_SQL = <<~SQL.squish.freeze
    (
      SELECT COUNT(*)
      FROM event_participants
      INNER JOIN event_teams ON event_teams.id = event_participants.event_team_id
      WHERE event_participants.event_id = events.id
        AND event_teams.slot IN ('team_one', 'team_two')
    )
  SQL

  belongs_to :user
  has_many :event_teams, dependent: :destroy
  has_many :event_participants, dependent: :destroy
  has_many :invitations, dependent: :destroy
  has_many :players, through: :event_participants, source: :user
  has_many :invited_users, through: :invitations, source: :user
  has_many :notifications, as: :notifiable

  validates :title, :location, :start_time, presence: true
  validate :start_time_must_be_in_the_future
  validates :number_of_participants, numericality: { only_integer: true, greater_than: 0 }
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validate :price_must_be_whole_euro
  validates :is_private, inclusion: { in: [ true, false ] }
  validates :latitude, :longitude, presence: true

  scope :upcoming, -> { where("start_time > ?", Time.current).order(:start_time) }
  scope :with_countable_participants_count, lambda {
    select(arel_table[Arel.star], Arel.sql("#{COUNTABLE_PARTICIPANTS_SQL} AS countable_participants_count"))
  }

  after_create_commit :set_teams_and_author

  def self.default_label_for(slot)
    I18n.t(SLOT_DEFAULT_LABEL_KEYS.fetch(slot.to_s))
  end

  def self.visible_to(user)
    return none if user.blank?

    where(is_private: false)
      .or(where(user_id: user.id))
      .or(where(id: EventParticipant.where(user_id: user.id).select(:event_id)))
      .or(where(id: Invitation.where(user_id: user.id).select(:event_id)))
      .or(where(is_private: true, user_id: Friendship.accepted_friend_ids_for(user)))
  end

  def self.private_visible_to(user)
    return none if user.blank?

    where(is_private: true, user_id: user.id)
      .or(where(is_private: true, user_id: Friendship.accepted_friend_ids_for(user)))
  end

  def set_teams_and_author
    TEAM_SLOTS.each do |slot|
      event_teams.create!(slot: slot, label: self.class.default_label_for(slot))
    end
    event_participants.create!(user: user, event_team: event_teams.find_by!(slot: :team_one))
  end

  def participants_count
    return self[:countable_participants_count].to_i if has_attribute?(:countable_participants_count)

    event_participants.joins(:event_team).merge(EventTeam.countable_teams).count
  end

  def registrations_count
    event_participants.count
  end

  def spots_remaining
    [ number_of_participants - participants_count, 0 ].max
  end

  def bench_user_ids
    event_participants.joins(:event_team).merge(EventTeam.bench).pluck(:user_id)
  end

  def reminder_due_at
    start_time - 24.hours
  end

  def countable_slots_full?
    participants_count >= number_of_participants
  end

  def countable_slots_per_team
    number_of_participants / 2
  end

  def countable_slots_for(team)
    return 0 unless team.countable?

    team.team_one? ? number_of_participants / 2 : (number_of_participants + 1) / 2
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
    return true unless is_private

    am_i_the_author?(user) || in_this_event?(user) || invited?(user) || user.is_friend_with?(self.user)
  end

  def joinable_by?(user)
    viewable_by?(user)
  end

  def invited?(user)
    invitations.exists?(user: user)
  end

  def fill_level
    return :full if countable_slots_full?
    return :tight if participants_count >= (number_of_participants * 2 / 3)

    :open
  end

  private

  def start_time_must_be_in_the_future
    return if start_time.blank? || start_time >= Time.current

    errors.add(:start_time, :in_the_past)
  end

  def price_must_be_whole_euro
    return if price.blank? || price.to_d == price.to_d.round(0)

    errors.add(:price, :not_whole_euro)
  end
end
