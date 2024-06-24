class AddMetaDataToAppDataArticles < ActiveRecord::Migration[5.2]
  def change
    add_column :app_data_articles, :meta, :json
  end
end
