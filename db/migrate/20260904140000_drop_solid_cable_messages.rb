# frozen_string_literal: true

# Live toasts move to Action Cable + Redis. Drop Solid Cable's Neon table.
class DropSolidCableMessages < ActiveRecord::Migration[8.0]
  def up
    drop_table :solid_cable_messages, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
