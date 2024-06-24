class AddRegistrationTypeAndRegistrationIdToOrganisationAddresses < ActiveRecord::Migration[5.2]
  def change
    add_column :organisation_addresses, :registration_type, :string
    add_column :organisation_addresses, :registration_id, :string
  end
end
