# frozen_string_literal: true

class Notification < ApplicationRecord
  include Notification::Delivery
  include Notification::Broadcasts

  belongs_to :user
  belongs_to :notifiable, polymorphic: true, optional: true

  enum :kind, {
    updated: 1,
    canceled: 2,
    reminder: 3,
    joined: 4,
    left: 5,
    invited: 6,
    friendship_requested: 7
  }

  validates :kind, presence: true

  scope :inbox, -> { where.not(kind: :friendship_requested) }
  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc).limit(20) }

  def self.mark_all_as_read_for!(user)
    user.notifications.inbox.unread.update_all(read: true, updated_at: Time.current)
  end

  def mark_as_read!
    update!(read: true)
  end

  def clickable?
    notifiable.present?
  end

  def target_url
    return unless clickable?
    return Rails.application.routes.url_helpers.friendships_path if notifiable.is_a?(Friendship)

    Rails.application.routes.url_helpers.polymorphic_path(notifiable)
  end
end
