class CreateAppDataAddressPreferences < ActiveRecord::Migration[5.2]
  def change
    create_table :app_data_address_preferences do |t|
      t.integer :preferable_id
      t.string :preferable_type
      t.integer :address_id

      t.timestamps
    end
  end
end
