class AddStreamToPushNotifications < ActiveRecord::Migration[5.2]
  def change
    add_column :push_notifications, :stream, :string
  end
end
