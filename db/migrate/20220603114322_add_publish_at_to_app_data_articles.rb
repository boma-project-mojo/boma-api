class AddPublishAtToAppDataArticles < ActiveRecord::Migration[6.1]
  def change
    add_column :app_data_articles, :publish_at, :datetime
  end
end
