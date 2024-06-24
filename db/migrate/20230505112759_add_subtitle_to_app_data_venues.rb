class AddSubtitleToAppDataVenues < ActiveRecord::Migration[7.0]
  def change
    add_column :app_data_venues, :subtitle, :string
  end
end
