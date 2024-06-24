class AddExternalMapLinkToAppDataVenues < ActiveRecord::Migration[5.0]
  def change
    add_column :app_data_venues, :external_map_link, :string
  end
end
