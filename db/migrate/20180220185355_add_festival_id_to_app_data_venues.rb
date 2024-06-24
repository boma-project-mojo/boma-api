class AddFestivalIdToAppDataVenues < ActiveRecord::Migration[5.0]
  def change
    add_column :app_data_venues, :festival_id, :string
    add_index :app_data_venues, :festival_id
  end
end
