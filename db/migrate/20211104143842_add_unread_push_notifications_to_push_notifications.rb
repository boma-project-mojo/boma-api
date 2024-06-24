class AddUnreadPushNotificationsToPushNotifications < ActiveRecord::Migration[5.2]
  def change
    add_column :push_notifications, :unread_push_notifications, :integer
  end
end
