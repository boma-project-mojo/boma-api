class AddDeviceDetailsToOrganisationAddresses < ActiveRecord::Migration[7.0]
  def change
    add_column :organisation_addresses, :device_details, :json
  end
end
