class AddOrganisationIdToPushNotifications < ActiveRecord::Migration[6.1]
  def change
    add_column :push_notifications, :organisation_id, :integer
  end
end
