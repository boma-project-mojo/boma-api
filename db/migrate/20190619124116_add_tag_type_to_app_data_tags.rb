class AddTagTypeToAppDataTags < ActiveRecord::Migration[5.0]
  def change
    add_column :app_data_tags, :tag_type, :string
  end
end
