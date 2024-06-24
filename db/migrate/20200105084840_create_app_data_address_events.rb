class CreateAppDataAddressEvents < ActiveRecord::Migration[5.2]
  def change
    create_table :app_data_address_events do |t|
      t.integer :address_id
      t.integer :event_id

      t.timestamps
    end
  end
end
