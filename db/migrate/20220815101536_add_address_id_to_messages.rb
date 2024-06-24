class AddAddressIdToMessages < ActiveRecord::Migration[6.1]
  def change
    add_column :messages, :address_id, :int
  end
end
