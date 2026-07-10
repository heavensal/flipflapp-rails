class EventTeam < ApplicationRecord
  LABEL_FORMAT = /\A[[:alnum:] ]+\z/
  COUNTABLE_SLOTS = %w[team_one team_two].freeze

  belongs_to :event
  has_many :event_participants, dependent: :destroy

  enum :slot, { team_one: "team_one", team_two: "team_two", bench: "bench" }

  scope :countable_teams, -> { where(slot: COUNTABLE_SLOTS) }

  validates :slot, presence: true, uniqueness: { scope: :event_id }
  validates :label,
    presence: true,
    length: { maximum: 24 },
    format: { with: LABEL_FORMAT },
    uniqueness: { scope: :event_id, case_sensitive: false }
  validate :slot_cannot_change, on: :update
  validate :bench_label_cannot_change, on: :update
  validate :event_has_capacity_for_team, on: :create

  before_validation :normalize_label

  def countable?
    team_one? || team_two?
  end

  def renamable_by?(user)
    countable? && event.in_this_event?(user)
  end

  def in_this_team?(user)
    event_participants.exists?(user: user)
  end

  def full?
    return false unless countable?

    event_participants.size >= event.countable_slots_per_team
  end

  def joinable?
    bench? || !full?
  end

  private

  def slot_cannot_change
    return unless slot_changed?

    errors.add(:slot, :immutable)
  end

  def bench_label_cannot_change
    return unless bench? && label_changed?

    errors.add(:label, :immutable)
  end

  def event_has_capacity_for_team
    return unless event
    return if event.event_teams.count < Event::TEAM_SLOTS.size

    errors.add(:base, :too_many_teams)
  end

  def normalize_label
    return if label.blank?

    self.label = label.strip.gsub(/\s+/, " ")
  end
end
