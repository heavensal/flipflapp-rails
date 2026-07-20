module AdminHelper
  def admin_model_name(resource)
    t("admin.models.#{resource.route_key}")
  end

  def admin_format_value(record, column)
    value = record.public_send(column)
    return "—" if value.nil?

    case column
    when "avatar"
      value.present? ? image_tag(record.avatar.url, class: "h-16 w-16 rounded-full object-cover") : "—"
    when "payload"
      content_tag(:pre, JSON.pretty_generate(value), class: "text-xs whitespace-pre-wrap")
    when "kind"
      record.kind
    when "slot"
      record.slot
    else
      case value
      when TrueClass, FalseClass then value ? t("admin.labels.yes") : t("admin.labels.no")
      when Time, ActiveSupport::TimeWithZone then value.to_fs(:long)
      when Date then value.to_fs
      else value.to_s
      end
    end
  end

  def admin_field_for(form, resource, column)
    record = form.object
    return if resource.readonly_columns.include?(column)

    case column
    when "avatar"
      form.file_field column, class: admin_input_classes
    when "description"
      form.text_area column, rows: 4, class: admin_input_classes
    when "payload"
      form.text_area column, value: JSON.pretty_generate(record.public_send(column) || {}), rows: 6, class: admin_input_classes
    when "is_private", "read"
      form.check_box column, class: "rounded border-white/30"
    when "kind"
      form.select column, Notification.kinds.keys, {}, class: admin_input_classes
    when "slot"
      form.select column, EventTeam.slots.keys, {}, class: admin_input_classes
    when "role"
      form.select column, User::ROLES, {}, class: admin_input_classes
    when "status"
      form.select column, %w[pending accepted declined], {}, class: admin_input_classes
    when "start_time", "confirmed_at", "confirmation_sent_at", "reset_password_sent_at",
         "remember_created_at", "current_sign_in_at", "last_sign_in_at", "created_at", "updated_at"
      form.datetime_local_field column, class: admin_input_classes
    when "price", "latitude", "longitude"
      form.number_field column, step: :any, class: admin_input_classes
    when "number_of_participants", "sign_in_count", "user_id", "event_id", "event_team_id",
         "sender_id", "receiver_id", "notifiable_id"
      form.number_field column, class: admin_input_classes
    when "notifiable_type"
      form.select column, %w[Event], { include_blank: true }, class: admin_input_classes
    else
      form.text_field column, class: admin_input_classes
    end
  end

  def admin_input_classes
    "w-full rounded-lg bg-white/10 border border-white/20 px-3 py-2 text-white"
  end

  def admin_association_resource(association_name, record)
    reflection = record.class.reflect_on_association(association_name)
    return unless reflection

    Admin::Resource.for_model(reflection.klass)
  end

  def admin_path_for_record(record)
    entry = Admin::Resource.for_model(record)
    return unless entry

    entry.admin_path(record, self)
  end
end
