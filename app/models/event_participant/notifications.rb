# frozen_string_literal: true

module EventParticipant::Notifications
  extend ActiveSupport::Concern

  included do
    after_create_commit :notify_joining
    after_update_commit :notify_team_switch, if: :saved_change_to_event_team_id?
    after_destroy_commit :notify_leaving
  end

  def notify_joining
    deliver_notifications(:joined) if event_team.countable?
  end

  def notify_leaving
    return unless Event.exists?(event_id)
    return unless event_team&.countable?

    deliver_notifications(:left)
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

  def deliver_notifications(kind)
    recipient_ids = team_notification_recipients(kind).pluck(:id)
    return if recipient_ids.empty?

    Notification.deliver_many!(
      user_ids: recipient_ids,
      kind: kind,
      notifiable: event,
      payload: {
        title: event.title,
        start_time: event.start_time,
        player: user.first_name
      }
    )
  end

  def team_notification_recipients(kind)
    slots = kind.to_sym == :left ? %w[team_one team_two bench] : EventTeam::COUNTABLE_SLOTS

    User.where(
      id: event.event_participants
        .joins(:event_team)
        .where(event_teams: { slot: slots })
        .where.not(user_id: user_id)
        .select(:user_id)
    )
  end
end
