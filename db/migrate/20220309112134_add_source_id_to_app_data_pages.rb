class AddSourceIdToAppDataPages < ActiveRecord::Migration[6.1]
  def change
    add_column :app_data_pages, :source_id, :string
  end
end
