class AddSlotAndRenameNameToLabelOnEventTeams < ActiveRecord::Migration[8.0]
  # `slot` is immutable squad identity (team_one, team_two, bench).
  # `label` is display text stored in the DB — often the locale default at creation time
  # (see config/locales/<locale>/event_team.yml), but may be a custom rename (e.g. "Real Madrid").
  #
  # Backfill: preserve historical squad identity from creation order per event.
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
    say_with_time "Backfilling event_team slots (creation order)" do
      EventTeam.reset_column_information

      EventTeam.distinct.pluck(:event_id).each do |event_id|
        EventTeam.where(event_id: event_id).order(:id).each_with_index do |team, index|
          slot = ORDERED_SLOTS[index]
          unless slot
            raise ActiveRecord::IrreversibleMigration,
              "No slot left for event_team #{team.id} (event #{event_id})"
          end

          team.update_columns(slot: slot)
        end
      end

      remaining = EventTeam.where(slot: nil).count
      raise ActiveRecord::IrreversibleMigration, "#{remaining} event_teams still missing slot" if remaining.positive?
    end
  end
end
