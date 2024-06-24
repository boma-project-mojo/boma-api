class RemoveDefaultArticleTypeFromAppDataArticles < ActiveRecord::Migration[6.1]
  def change
    change_column_default(:app_data_articles, :article_type, nil)
  end
end
