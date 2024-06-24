class AddRegistrationIdToPushNotifications < ActiveRecord::Migration[5.2]
  def change
    add_column :push_notifications, :registration_id, :string
  end
end
