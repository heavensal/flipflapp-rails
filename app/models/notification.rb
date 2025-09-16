class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :notifiable, polymorphic: true, optional: true

  enum :kind, {
    created: 0,
    updated: 1,
    canceled: 2,
    reminder: 3,
    joined: 4,
    left: 5,
    invited: 6
  }

  validates :kind, presence: true

  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc).limit(20) }


  def mark_as_read!
    update(read: true)
  end

  def clickable?
    notifiable.present?
  end

  def target_url
    return unless clickable?
    Rails.application.routes.url_helpers.polymorphic_path(notifiable)
  end



end
