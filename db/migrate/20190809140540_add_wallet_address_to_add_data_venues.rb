class AddWalletAddressToAddDataVenues < ActiveRecord::Migration[5.0]
  def change
    add_column :app_data_venues, :wallet_address, :string
  end
end
