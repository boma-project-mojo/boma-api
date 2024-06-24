class AddImageToAppDataVenues < ActiveRecord::Migration[5.0]
  def change
    add_column :app_data_venues, :image, :string
  end
end
