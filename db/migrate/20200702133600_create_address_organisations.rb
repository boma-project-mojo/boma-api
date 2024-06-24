class CreateAddressOrganisations < ActiveRecord::Migration[5.2]
  def change
    create_table :organisation_addresses do |t|
      t.integer :address_id
      t.integer :organisation_id
      t.json :settings
      t.integer :unread_push_notifications
			t.string :app_version
      t.string :fcm_token

      t.timestamps
    end
  end
end
