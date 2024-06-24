class AddIndexForAddressIdToPushNotifications < ActiveRecord::Migration[7.0]
  def change
    add_index :push_notifications, [:address_id]
  end
end
