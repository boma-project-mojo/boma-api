class AddArticleTypeToAppDataArticles < ActiveRecord::Migration[5.2]
  def change
  	add_column :app_data_articles, :article_type, :string, :default => 'boma_article'
  	add_column :app_data_articles, :wallet_address, :string
  end
end
