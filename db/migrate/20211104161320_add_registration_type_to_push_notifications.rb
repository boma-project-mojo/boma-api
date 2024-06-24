class AddRegistrationTypeToPushNotifications < ActiveRecord::Migration[5.2]
  def change
    add_column :push_notifications, :registration_type, :string
  end
end
