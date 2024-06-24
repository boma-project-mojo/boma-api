class AddWalletNonceToOrganisations < ActiveRecord::Migration[7.0]
  def change
    add_column :organisations, :address_nonce, :integer
  end
end
