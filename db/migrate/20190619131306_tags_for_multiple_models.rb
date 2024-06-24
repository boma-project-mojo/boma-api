class TagsForMultipleModels < ActiveRecord::Migration[5.0]
  def change
    rename_table :app_data_productions_tags, :app_data_taggings
    rename_column :app_data_taggings, :production_id, :taggable_id
    add_column :app_data_taggings, :taggable_type, :string, :default => 'AppData::Production'
  end
end
