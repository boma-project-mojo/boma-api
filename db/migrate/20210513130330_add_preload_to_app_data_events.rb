class AddPreloadToAppDataEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :app_data_events, :preload, :boolean
  end
end
