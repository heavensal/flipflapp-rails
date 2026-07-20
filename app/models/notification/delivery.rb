# frozen_string_literal: true

module Notification::Delivery
  extend ActiveSupport::Concern

  class_methods do
    def deliver_one!(user:, kind:, notifiable:, payload:)
      Notifications::DeliverOneJob.perform_later(
        user_id: user.id,
        kind: kind.to_s,
        notifiable_gid: notifiable&.to_gid&.to_s,
        payload: serialize_payload(payload)
      )
    end

    def deliver_many!(user_ids:, kind:, notifiable:, payload:)
      ids = Array(user_ids).uniq
      return if ids.empty?

      Notifications::DeliverManyJob.perform_later(
        user_ids: ids,
        kind: kind.to_s,
        notifiable_gid: notifiable&.to_gid&.to_s,
        payload: serialize_payload(payload)
      )
    end

    def serialize_payload(payload)
      payload.to_h.transform_values do |value|
        value.respond_to?(:iso8601) ? value.iso8601 : value
      end
    end
  end
end
