class RequireCoordinatesOnEvents < ActiveRecord::Migration[8.0]
  def change
    add_check_constraint :events, "latitude IS NOT NULL",
                         name: "events_latitude_not_null", validate: false
    add_check_constraint :events, "longitude IS NOT NULL",
                         name: "events_longitude_not_null", validate: false
  end
end
