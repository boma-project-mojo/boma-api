class AddFestivalIdToAppDataPages < ActiveRecord::Migration[5.0]
  def change
    add_column :app_data_pages, :festival_id, :string
    add_index :app_data_pages, :festival_id
  end
end
