class AddSourceIdToAppDataTags < ActiveRecord::Migration[5.0]
  def change
    add_column :app_data_tags, :source_id, :string
  end
end
