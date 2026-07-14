module Admin
  class Resource
    ENTRY = Data.define(
      :key,
      :model_class,
      :associations,
      :hidden_columns,
      :readonly_columns,
      :index_columns
    )

    ENTRIES = {
      users: ENTRY.new(
        key: :users,
        model_class: User,
        associations: %i[events event_participants notifications sent_friendships received_friendships],
        hidden_columns: %w[
          encrypted_password reset_password_token remember_created_at confirmation_token tokens
        ],
        readonly_columns: %w[
          sign_in_count current_sign_in_at last_sign_in_at current_sign_in_ip last_sign_in_ip
          reset_password_sent_at
        ],
        index_columns: %w[id email username first_name last_name role created_at]
      ),
      events: ENTRY.new(
        key: :events,
        model_class: Event,
        associations: %i[event_teams event_participants user notifications],
        hidden_columns: [],
        readonly_columns: [],
        index_columns: %w[id title location start_time user_id is_private created_at]
      ),
      event_teams: ENTRY.new(
        key: :event_teams,
        model_class: EventTeam,
        associations: %i[event_participants event],
        hidden_columns: [],
        readonly_columns: [],
        index_columns: %w[id event_id slot label created_at]
      ),
      event_participants: ENTRY.new(
        key: :event_participants,
        model_class: EventParticipant,
        associations: %i[user event event_team],
        hidden_columns: [],
        readonly_columns: [],
        index_columns: %w[id user_id event_id event_team_id created_at]
      ),
      friendships: ENTRY.new(
        key: :friendships,
        model_class: Friendship,
        associations: %i[sender receiver],
        hidden_columns: [],
        readonly_columns: [],
        index_columns: %w[id sender_id receiver_id status created_at]
      ),
      notifications: ENTRY.new(
        key: :notifications,
        model_class: Notification,
        associations: %i[user],
        hidden_columns: [],
        readonly_columns: [],
        index_columns: %w[id user_id kind read notifiable_type notifiable_id created_at]
      )
    }.freeze

    class << self
      def all
        ENTRIES.values
      end

      def find(key)
        ENTRIES.fetch(key.to_sym)
      end

      def for_model(record_or_class)
        klass = record_or_class.is_a?(Class) ? record_or_class : record_or_class.class
        entry = ENTRIES.values.find { |item| item.model_class == klass }
        Admin::Resource.new(entry) if entry
      end
    end

    def initialize(entry)
      @entry = entry
    end

    delegate :key, :model_class, :associations, :hidden_columns, :readonly_columns, :index_columns, to: :@entry

    def route_key
      key.to_s
    end

    def singular_route_key
      route_key.singularize
    end

    def display_columns
      model_class.column_names - hidden_columns
    end

    def writable_columns
      display_columns - readonly_columns - %w[id created_at updated_at]
    end

    def association_records(record, name)
      reflection = model_class.reflect_on_association(name)
      return [] unless reflection

      if reflection.collection?
        record.public_send(name).order(id: :desc)
      elsif record.public_send(name)
        [ record.public_send(name) ]
      else
        []
      end
    end

    def player_path(record, helpers)
      case record
      when User then helpers.user_path(record)
      when Event then helpers.event_path(record)
      when EventTeam then helpers.event_path(record.event)
      when EventParticipant then helpers.event_path(record.event)
      when Friendship then helpers.friendships_path
      when Notification then helpers.notifications_list_path
      end
    end

    def admin_path(record, helpers)
      helpers.public_send(:"admin_#{singular_route_key}_path", record)
    end

    def admin_index_path(helpers)
      helpers.public_send(:"admin_#{route_key}_path")
    end

    def record_label(record)
      case record
      when User then "#{record.username} (#{record.email})"
      when Event then record.title
      when EventTeam then "#{record.slot} — #{record.label}"
      when EventParticipant then "User ##{record.user_id} on Event ##{record.event_id}"
      when Friendship then "##{record.id} #{record.status}"
      when Notification then "##{record.id} #{record.kind}"
      else "##{record.id}"
      end
    end
  end
end
