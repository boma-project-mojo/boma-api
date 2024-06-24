class AddFestivalIdToAppDataTags < ActiveRecord::Migration[5.0]
  def change
    add_column :app_data_tags, :festival_id, :string
    add_index :app_data_tags, :festival_id
  end
end
