class AddEventTypeOfToAppDataEvents < ActiveRecord::Migration[5.0]
  def change
    add_column :app_data_events, :event_type, :string
  end
end
