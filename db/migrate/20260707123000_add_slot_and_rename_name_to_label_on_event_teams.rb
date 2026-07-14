class AddSlotAndRenameNameToLabelOnEventTeams < ActiveRecord::Migration[8.0]
  def up
    add_column :event_teams, :slot, :string
    rename_column :event_teams, :name, :label

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
end
