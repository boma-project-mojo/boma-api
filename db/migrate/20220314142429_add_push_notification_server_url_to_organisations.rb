class AddPushNotificationServerUrlToOrganisations < ActiveRecord::Migration[6.1]
  def change
    add_column :organisations, :push_notification_server_api_endpoint, :string
    add_column :organisations, :push_notification_server_username, :string
    add_column :organisations, :push_notification_server_password, :string
  end
end
