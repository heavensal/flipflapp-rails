class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.string :title, null: false
      t.text :description
      t.string :location, null: false
      t.datetime :start_time, null: false
      t.integer :number_of_participants, null: false, default: 10
      t.decimal :price, precision: 10, scale: 2, null: false, default: 10.0
      t.boolean :is_private, null: false, default: true

      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
  end
end
