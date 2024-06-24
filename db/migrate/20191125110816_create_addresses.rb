class CreateAddresses < ActiveRecord::Migration[5.2]
  def change
    create_table :addresses do |t|
      t.string :address
      t.string :fcm_token

      t.timestamps
    end
  end
end
