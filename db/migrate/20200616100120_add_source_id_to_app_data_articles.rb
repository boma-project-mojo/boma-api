class AddSourceIdToAppDataArticles < ActiveRecord::Migration[5.2]
  def change
    add_column :app_data_articles, :source_id, :string
  end
end
