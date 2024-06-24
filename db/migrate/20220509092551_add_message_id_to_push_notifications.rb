class AddMessageIdToPushNotifications < ActiveRecord::Migration[6.1]
  def change
    add_column :push_notifications, :message_id, :integer
  end
end
