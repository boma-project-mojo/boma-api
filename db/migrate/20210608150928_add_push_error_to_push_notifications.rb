class AddPushErrorToPushNotifications < ActiveRecord::Migration[5.2]
  def change
    add_column :push_notifications, :push_error, :string
  end
end
