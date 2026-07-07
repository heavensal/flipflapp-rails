class EventParticipant < ApplicationRecord
  belongs_to :user
  belongs_to :event
  belongs_to :event_team

  validates :user_id, uniqueness: { scope: [ :event_id ], message: "est déjà inscrit à cet événement" }

  after_create :notify_joining
  after_destroy :notify_leaving

  def notify_joining
    return unless team_notification_event?

    team_notification_recipients.find_each do |recipient|
      Notification.create!(
        user: recipient,
        notifiable: event,
        kind: :joined,
        payload: {
          title: event.title,
          start_time: event.start_time,
          player: user.first_name
        }
      )
    end
  end

  def notify_leaving
    return if event.destroyed?
    return unless team_notification_event?

    team_notification_recipients.find_each do |recipient|
      Notification.create!(
        user: recipient,
        notifiable: event,
        kind: :left,
        payload: {
          title: event.title,
          start_time: event.start_time,
          player: user.first_name
        }
      )
    end
  end

  def team_notification_event?
    event_team.countable?
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
