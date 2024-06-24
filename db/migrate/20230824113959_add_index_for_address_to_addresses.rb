class AddIndexForAddressToAddresses < ActiveRecord::Migration[7.0]
  def change
    add_index(:addresses, :address)
  end
end
