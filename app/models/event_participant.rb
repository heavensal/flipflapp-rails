class EventParticipant < ApplicationRecord
  belongs_to :user
  belongs_to :event
  belongs_to :event_team

  validates :user_id, uniqueness: { scope: :event_id }
  validate :countable_team_has_capacity, if: :targeting_countable_team?

  after_create :notify_joining
  after_update :notify_team_switch, if: :saved_change_to_event_team_id?
  after_destroy :notify_leaving

  def notify_joining
    deliver_notifications(:joined) if event_team.countable?
  end

  def notify_leaving
    return if event.destroyed?

    deliver_notifications(:left) if event_team.countable?
  end

  def notify_team_switch
    previous_team = EventTeam.find(saved_change_to_event_team_id.first)

    if previous_team.countable? && event_team.bench?
      deliver_notifications(:left)
    elsif previous_team.bench? && event_team.countable?
      deliver_notifications(:joined)
    end
  end

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

  def deliver_notifications(kind)
    recipient_ids = team_notification_recipients.pluck(:id)
    return if recipient_ids.empty?

    Notification.insert_all(
      recipient_ids.map do |recipient_id|
        {
          user_id: recipient_id,
          notifiable_type: "Event",
          notifiable_id: event.id,
          kind: Notification.kinds.fetch(kind),
          payload: {
            title: event.title,
            start_time: event.start_time,
            player: user.first_name
          },
          read: false,
          created_at: Time.current,
          updated_at: Time.current
        }
      end
    )
  end

  def team_notification_recipients
    User.where(
      id: event.event_participants
        .joins(:event_team)
        .merge(EventTeam.countable_teams)
        .where.not(user_id: user_id)
        .select(:user_id)
    )
  end
end
