class AddSourceIdToAppDataEvents < ActiveRecord::Migration[5.0]
  def change
    add_column :app_data_events, :source_id, :string
  end
end
