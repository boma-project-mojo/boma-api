class AddCityToAppDataVenues < ActiveRecord::Migration[5.2]
  def change
    add_column :app_data_venues, :city, :string
  end
end
