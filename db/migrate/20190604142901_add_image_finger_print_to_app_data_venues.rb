class AddImageFingerPrintToAppDataVenues < ActiveRecord::Migration[5.0]
  def change
    add_column :app_data_venues, :image_fingerprint, :string
  end
end
