class AddPrivateEventToAppDataEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :app_data_events, :private_event, :boolean, default: false
  end
end
