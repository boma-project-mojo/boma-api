class AddIncludeInClashfinderToAppDataVenues < ActiveRecord::Migration[6.1]
  def change
    add_column :app_data_venues, :include_in_clashfinder, :boolean, default: true
  end
end
