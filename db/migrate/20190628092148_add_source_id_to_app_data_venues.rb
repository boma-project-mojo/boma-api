class AddSourceIdToAppDataVenues < ActiveRecord::Migration[5.0]
  def change
    add_column :app_data_venues, :source_id, :string
  end
end
