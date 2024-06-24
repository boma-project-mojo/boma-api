class AddSendDataNotificationsToOrganisations < ActiveRecord::Migration[7.0]
  def change
    add_column :organisations, :send_data_notifications, :boolean, default: true

    Organisation.all.each do |org|
      org.update! send_data_notifications: false
    end
  end
end
