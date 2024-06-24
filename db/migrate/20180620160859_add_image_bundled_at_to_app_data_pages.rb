class AddImageBundledAtToAppDataPages < ActiveRecord::Migration[5.0]
  def change
    add_column :app_data_pages, :image_last_updated_at, :datetime        
    add_column :app_data_pages, :image_bundled_at, :datetime
  end
end
