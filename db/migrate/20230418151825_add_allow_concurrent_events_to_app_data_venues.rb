class AddAllowConcurrentEventsToAppDataVenues < ActiveRecord::Migration[7.0]
  def change
    add_column :app_data_venues, :allow_concurrent_events, :boolean
  end
end
