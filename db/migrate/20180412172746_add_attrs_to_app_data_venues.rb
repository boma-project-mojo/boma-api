class AddAttrsToAppDataVenues < ActiveRecord::Migration[5.0]
  def change
    add_column :app_data_venues, :menu, :text, :default => "<p></p>"
    add_column :app_data_venues, :dietary_requirements, :json
  end
end
