class AddSlotAndRenameNameToLabelOnEventTeams < ActiveRecord::Migration[8.0]
  # `slot` is immutable squad identity (team_one, team_two, bench).
  # `label` is display text stored in the DB — often the locale default at creation time
  # (see config/locales/<locale>/event_team.yml), but may be a custom rename (e.g. "Real Madrid").
  #
  # Backfill: map known default labels from shipped locales, then fall back to creation order
  # per event. Keep DEFAULT_LABELS_BY_SLOT in sync when adding a locale's default_label strings.
  DEFAULT_LABELS_BY_SLOT = {
    "team_one" => [
      "equipe 1",
      "équipe 1",
      "team 1"
    ],
    "team_two" => [
      "equipe 2",
      "équipe 2",
      "team 2"
    ],
    "bench" => [
      "sur le banc",
      "on the bench",
      "bench"
    ]
  }.freeze

  SLOT_BY_LABEL = DEFAULT_LABELS_BY_SLOT.each_with_object({}) do |(slot, labels), map|
    labels.each { |label| map[label] = slot }
  end.freeze

  ORDERED_SLOTS = %w[team_one team_two bench].freeze
  LABEL_MAX_LENGTH = 255

  class MigrationEventTeam < ApplicationRecord
    self.table_name = "event_teams"
  end

  def up
    if recreate_empty_legacy_table?
      recreate_empty_event_teams_table!
      return
    end

    add_slot_and_label_columns!
    migrate_event_team_rows if event_teams_count.positive?
    finalize_event_teams_table!
  end

  def down
    remove_index :event_teams, column: %i[event_id label], if_exists: true
    remove_index :event_teams, column: %i[event_id slot], if_exists: true
    change_column_null :event_teams, :slot, true if column_exists?(:event_teams, :slot)
    remove_column :event_teams, :slot if column_exists?(:event_teams, :slot)
    rename_column :event_teams, :label, :name if column_exists?(:event_teams, :label)
  end

  private

  def recreate_empty_legacy_table?
    event_teams_count.zero? &&
      column_exists?(:event_teams, :name) &&
      !column_exists?(:event_teams, :event_id)
  end

  def recreate_empty_event_teams_table!
    say_with_time "Recreating empty legacy event_teams table (id/name only)" do
      drop_table :event_teams
      create_table :event_teams do |t|
        t.string :label, null: false
        t.references :event, null: false, foreign_key: true
        t.string :slot, null: false
        t.timestamps
      end
      add_index :event_teams, %i[event_id slot], unique: true
      add_index :event_teams, %i[event_id label], unique: true
    end
  end

  def add_slot_and_label_columns!
    add_column :event_teams, :slot, :string unless column_exists?(:event_teams, :slot)
    rename_column :event_teams, :name, :label if column_exists?(:event_teams, :name)
  end

  def finalize_event_teams_table!
    change_column_null :event_teams, :slot, false
    add_index :event_teams, %i[event_id slot], unique: true unless index_exists?(:event_teams, %i[event_id slot])
    add_index :event_teams, %i[event_id label], unique: true unless index_exists?(:event_teams, %i[event_id label])
  end

  def migrate_event_team_rows
    unless column_exists?(:event_teams, :event_id)
      raise ActiveRecord::IrreversibleMigration, "event_teams.event_id is required to backfill rows"
    end

    backfill_slots
    deduplicate_labels_per_event
  end

  def event_teams_count
    select_value("SELECT COUNT(*) FROM event_teams").to_i
  end

  def backfill_slots
    say_with_time "Backfilling event_team slots (locale defaults + creation order)" do
      MigrationEventTeam.reset_column_information

      MigrationEventTeam.distinct.pluck(:event_id).each do |event_id|
        backfill_slots_for_event(event_id)
      end

      remaining = MigrationEventTeam.where(slot: nil).count
      raise ActiveRecord::IrreversibleMigration, "#{remaining} event_teams still missing slot" if remaining.positive?
    end
  end

  def backfill_slots_for_event(event_id)
    teams = MigrationEventTeam.where(event_id: event_id).order(:id)
    team_count = teams.count

    if team_count > ORDERED_SLOTS.size
      raise ActiveRecord::IrreversibleMigration,
            "event #{event_id} has #{team_count} teams (max #{ORDERED_SLOTS.size})"
    end

    taken_slots = []

    teams.each do |team|
      slot = SLOT_BY_LABEL[normalize_label(team.label)]
      next unless slot
      next if taken_slots.include?(slot)

      team.update_columns(slot: slot)
      taken_slots << slot
    end

    MigrationEventTeam.where(event_id: event_id, slot: nil).order(:id).each do |team|
      slot = (ORDERED_SLOTS - taken_slots).first
      raise ActiveRecord::IrreversibleMigration,
            "No slot left for event_team #{team.id} (event #{event_id})" unless slot

      team.update_columns(slot: slot)
      taken_slots << slot
    end
  end

  def deduplicate_labels_per_event
    say_with_time "Deduplicating event_team labels (case-insensitive, per event)" do
      MigrationEventTeam.reset_column_information

      MigrationEventTeam.distinct.pluck(:event_id).each do |event_id|
        used_labels = {}
        used_normalized_labels = {}

        MigrationEventTeam.where(event_id: event_id).order(:id).each do |team|
          current_label = team.label.to_s
          key = normalize_label(current_label)

          if used_normalized_labels[key]
            deduplicated_label = next_available_label(
              base_label: current_label,
              team_id: team.id,
              used_labels: used_labels,
              used_normalized_labels: used_normalized_labels
            )
            team.update_columns(label: deduplicated_label)
            current_label = deduplicated_label
            key = normalize_label(current_label)
          end

          used_labels[current_label] = true
          used_normalized_labels[key] = true
        end
      end
    end
  end

  def next_available_label(base_label:, team_id:, used_labels:, used_normalized_labels:)
    attempt = 0

    loop do
      suffix = attempt.zero? ? " (#{team_id})" : " (#{team_id}-#{attempt + 1})"
      max_base_length = LABEL_MAX_LENGTH - suffix.length
      raise ActiveRecord::IrreversibleMigration, "Unable to deduplicate label for event_team #{team_id}" if max_base_length <= 0

      candidate = "#{base_label.mb_chars.limit(max_base_length)}#{suffix}"
      normalized_candidate = normalize_label(candidate)

      return candidate unless used_labels[candidate] || used_normalized_labels[normalized_candidate]

      attempt += 1
    end
  end

  def normalize_label(label)
    label.to_s.strip.downcase
  end
end
