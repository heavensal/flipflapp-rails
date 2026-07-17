# frozen_string_literal: true

class EventParticipant < ApplicationRecord
  include EventParticipant::Notifications

  belongs_to :user
  belongs_to :event
  belongs_to :event_team

  validates :user_id, uniqueness: { scope: :event_id }
  validate :countable_team_has_capacity, if: :targeting_countable_team?

  private

  def targeting_countable_team?
    return false unless event_team&.countable?
    return true if new_record?

    will_save_change_to_event_team_id?
  end

  def countable_team_has_capacity
    if event_team.full?
      errors.add(:event_team, :team_full)
      return
    end

    return if moving_between_countable_teams?
    return unless event.countable_slots_full?

    errors.add(:event_team, :countable_full)
  end

  def moving_between_countable_teams?
    return false unless persisted? && will_save_change_to_event_team_id?

    previous_team = EventTeam.find_by(id: event_team_id_in_database)
    previous_team&.countable? && event_team.countable?
  end
end
