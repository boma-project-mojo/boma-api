class RemoveGoRushConfigFromOrganisations < ActiveRecord::Migration[7.0]
  def change
    remove_column :organisations, :push_notification_server_api_endpoint
    remove_column :organisations, :push_notification_server_username
    remove_column :organisations, :push_notification_server_password
  end
end