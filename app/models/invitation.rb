# frozen_string_literal: true

class Invitation < ApplicationRecord
  belongs_to :event
  belongs_to :user

  validates :user_id, uniqueness: { scope: :event_id }
end
