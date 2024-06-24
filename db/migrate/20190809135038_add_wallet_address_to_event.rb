class AddWalletAddressToEvent < ActiveRecord::Migration[5.0]
  def change
    add_column :app_data_events, :wallet_address, :string
  end
end
