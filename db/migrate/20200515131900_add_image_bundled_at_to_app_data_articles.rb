class AddImageBundledAtToAppDataArticles < ActiveRecord::Migration[5.2]
  def change
    add_column :app_data_articles, :image_bundled_at, :datetime
  end
end
