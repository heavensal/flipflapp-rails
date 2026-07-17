# frozen_string_literal: true

module Notification::Delivery
  extend ActiveSupport::Concern

  class_methods do
    def deliver_one!(user:, kind:, notifiable:, payload:)
      create!(
        user: user,
        kind: kind,
        notifiable: notifiable,
        payload: payload,
        read: false
      )
    end

    def deliver_many!(user_ids:, kind:, notifiable:, payload:)
      ids = Array(user_ids).uniq
      return if ids.empty?

      now = Time.current
      kind_value = kinds.fetch(kind.to_s)

      insert_all(
        ids.map do |user_id|
          {
            user_id: user_id,
            notifiable_type: notifiable&.class&.name,
            notifiable_id: notifiable&.id,
            kind: kind_value,
            payload: payload,
            read: false,
            created_at: now,
            updated_at: now
          }
        end
      )
    end
  end
end
