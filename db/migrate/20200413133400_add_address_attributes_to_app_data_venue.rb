class AddAddressAttributesToAppDataVenue < ActiveRecord::Migration[5.2]
  def change
    add_column :app_data_venues, :postcode, :string
    add_column :app_data_venues, :address_line_1, :string
    add_column :app_data_venues, :address_line_2, :string
  end
end
