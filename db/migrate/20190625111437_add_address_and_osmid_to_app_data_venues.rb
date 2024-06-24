class AddAddressAndOsmidToAppDataVenues < ActiveRecord::Migration[5.0]
  def change
    add_column :app_data_venues, :address, :string
    add_column :app_data_venues, :osm_id, :string
  end
end
