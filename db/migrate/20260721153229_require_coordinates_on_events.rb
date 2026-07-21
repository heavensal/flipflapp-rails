class RequireCoordinatesOnEvents < ActiveRecord::Migration[8.0]
  def change
    change_column_null :events, :latitude, false
    change_column_null :events, :longitude, false
  end
end
