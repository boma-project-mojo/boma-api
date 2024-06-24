class AddDeletedAtToAppDataEvents < ActiveRecord::Migration[5.0]
  def change
    add_column :app_data_events, :deleted_at, :datetime
    add_index :app_data_events, :deleted_at
  end
end
