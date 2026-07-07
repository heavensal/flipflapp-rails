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

  class EventTeam < ApplicationRecord
    self.table_name = "event_teams"
  end

  def up
    add_column :event_teams, :slot, :string
    rename_column :event_teams, :name, :label

    backfill_slots

    change_column_null :event_teams, :slot, false
    add_index :event_teams, %i[event_id slot], unique: true
    add_index :event_teams, %i[event_id label], unique: true
  end

  def down
    remove_index :event_teams, column: %i[event_id label]
    remove_index :event_teams, column: %i[event_id slot]
    remove_column :event_teams, :slot
    rename_column :event_teams, :label, :name
  end

  private

  def backfill_slots
    say_with_time "Backfilling event_team slots (locale defaults + creation order)" do
      EventTeam.reset_column_information

      EventTeam.find_each do |team|
        normalized_label = normalize_label(team.label)
        slot = SLOT_BY_LABEL[normalized_label]
        team.update_columns(slot: slot) if slot
      end

      event_ids_with_missing_slots = EventTeam.where(slot: nil).distinct.pluck(:event_id)
      event_ids_with_missing_slots.each do |event_id|
        teams_without_slot = EventTeam.where(event_id: event_id, slot: nil).order(:id)
        taken_slots = EventTeam.where(event_id: event_id).where.not(slot: nil).pluck(:slot)
        available_slots = ORDERED_SLOTS - taken_slots

        teams_without_slot.each do |team|
          slot = available_slots.shift
          raise ActiveRecord::IrreversibleMigration, "No slot left for event_team #{team.id} (event #{event_id})" unless slot

          team.update_columns(slot: slot)
        end
      end

      remaining = EventTeam.where(slot: nil).count
      raise ActiveRecord::IrreversibleMigration, "#{remaining} event_teams still missing slot" if remaining.positive?
    end
  end

  def normalize_label(label)
    label.to_s.strip.downcase
  end
end
