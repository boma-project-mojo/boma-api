class CreateActivities < ActiveRecord::Migration[5.2]
  def change
    create_table :activities do |t|
      t.integer :address_id
      t.string :activity_type
      t.integer :notification_id
      t.string :app_version
      t.string :timezone

      t.timestamps
    end
  end
end
