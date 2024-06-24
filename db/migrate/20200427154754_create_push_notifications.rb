class CreatePushNotifications < ActiveRecord::Migration[5.2]
  def change
    create_table :push_notifications do |t|
      t.string :subject
      t.string :body
      t.string :pushed_state
      t.integer :festival_id
      t.integer :address_id
      t.string :messagable_type
      t.integer :messagable_id
      t.datetime :deleted_at
      t.string :topic_id
      t.string :notification_type

      t.timestamps
    end
  end
end
