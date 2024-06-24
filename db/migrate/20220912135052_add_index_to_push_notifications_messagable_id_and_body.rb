class AddIndexToPushNotificationsMessagableIdAndBody < ActiveRecord::Migration[6.1]
  def change
    add_index :push_notifications, [:messagable_id, :body]
  end
end
