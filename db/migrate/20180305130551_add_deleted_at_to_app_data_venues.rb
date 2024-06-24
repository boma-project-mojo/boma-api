class AddDeletedAtToAppDataVenues < ActiveRecord::Migration[5.0]
  def change
    add_column :app_data_venues, :deleted_at, :datetime
    add_index :app_data_venues, :deleted_at
  end
end
