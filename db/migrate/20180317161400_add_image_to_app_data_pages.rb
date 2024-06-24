class AddImageToAppDataPages < ActiveRecord::Migration[5.0]
  def change
    add_column :app_data_pages, :image, :string
  end
end
