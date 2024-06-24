class AddDeletedAtToAppDataTags < ActiveRecord::Migration[5.0]
  def change
    add_column :app_data_tags, :deleted_at, :datetime
    add_index :app_data_tags, :deleted_at
  end
end
