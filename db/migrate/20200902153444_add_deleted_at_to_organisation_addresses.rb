class AddDeletedAtToOrganisationAddresses < ActiveRecord::Migration[5.2]
  def change
  	add_column :organisation_addresses, :deleted_at, :datetime
    add_index :organisation_addresses, :deleted_at
  end
end
