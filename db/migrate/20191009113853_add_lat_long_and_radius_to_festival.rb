class AddLatLongAndRadiusToFestival < ActiveRecord::Migration[5.0]
  def change
    add_column :festivals, :center_lat, :string
    add_column :festivals, :center_long, :string
    add_column :festivals, :location_radius, :string
  end
end
