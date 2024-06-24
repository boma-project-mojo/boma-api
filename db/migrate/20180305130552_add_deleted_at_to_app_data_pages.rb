class AddDeletedAtToAppDataPages < ActiveRecord::Migration[5.0]
  def change
    add_column :app_data_pages, :deleted_at, :datetime
    add_index :app_data_pages, :deleted_at
  end
end
