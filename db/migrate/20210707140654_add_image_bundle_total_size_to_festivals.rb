class AddImageBundleTotalSizeToFestivals < ActiveRecord::Migration[5.2]
  def change
    add_column :festivals, :total_images_filesize, :float, default: 0
  end
end
