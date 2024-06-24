class AddDescriptionToAppDataTags < ActiveRecord::Migration[5.2]
  def change
    add_column :app_data_tags, :description, :string
  end
end
