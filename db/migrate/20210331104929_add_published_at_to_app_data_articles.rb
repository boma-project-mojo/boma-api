class AddPublishedAtToAppDataArticles < ActiveRecord::Migration[5.2]
  def change
    add_column :app_data_articles, :published_at, :datetime
  end
end
