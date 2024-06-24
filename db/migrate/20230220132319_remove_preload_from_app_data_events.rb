class RemovePreloadFromAppDataEvents < ActiveRecord::Migration[7.0]
  def change
    remove_column :app_data_events, :preload
  end
end
