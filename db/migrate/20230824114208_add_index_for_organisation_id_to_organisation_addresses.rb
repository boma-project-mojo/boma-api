class AddIndexForOrganisationIdToOrganisationAddresses < ActiveRecord::Migration[7.0]
  def change
    add_index(:organisation_addresses, :organisation_id)
  end
end
