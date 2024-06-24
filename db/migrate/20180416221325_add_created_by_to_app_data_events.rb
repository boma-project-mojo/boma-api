class AddCreatedByToAppDataEvents < ActiveRecord::Migration[5.0]
  def change
    add_column :app_data_events, :created_by, :string
    add_index :app_data_events, :created_by
  end
end
