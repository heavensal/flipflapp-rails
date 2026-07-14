class AddSlotAndRenameNameToLabelOnEventTeams < ActiveRecord::Migration[8.0]
  def up
    add_column :event_teams, :slot, :string
    rename_column :event_teams, :name, :label

    backfill_slots
    deduplicate_labels_per_event

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

      EventTeam.distinct.pluck(:event_id).each do |event_id|
        backfill_slots_for_event(event_id)
      end

      remaining = EventTeam.where(slot: nil).count
      raise ActiveRecord::IrreversibleMigration, "#{remaining} event_teams still missing slot" if remaining.positive?
    end
  end

  def backfill_slots_for_event(event_id)
    teams = EventTeam.where(event_id: event_id).order(:id)
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

    EventTeam.where(event_id: event_id, slot: nil).order(:id).each do |team|
      slot = (ORDERED_SLOTS - taken_slots).first
      raise ActiveRecord::IrreversibleMigration,
            "No slot left for event_team #{team.id} (event #{event_id})" unless slot

      team.update_columns(slot: slot)
      taken_slots << slot
    end
  end

  def deduplicate_labels_per_event
    say_with_time "Deduplicating event_team labels (case-insensitive, per event)" do
      EventTeam.reset_column_information

      EventTeam.distinct.pluck(:event_id).each do |event_id|
        seen_normalized_labels = {}

        EventTeam.where(event_id: event_id).order(:id).each do |team|
          key = normalize_label(team.label)

          if seen_normalized_labels[key]
            team.update_columns(label: "#{team.label} (#{team.id})")
          else
            seen_normalized_labels[key] = true
          end
        end
      end
    end
  end

  def normalize_label(label)
    label.to_s.strip.downcase
  end
end
