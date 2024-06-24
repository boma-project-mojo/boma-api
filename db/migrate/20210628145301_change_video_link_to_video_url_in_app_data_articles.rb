class ChangeVideoLinkToVideoUrlInAppDataArticles < ActiveRecord::Migration[5.2]
  def change
  	rename_column :app_data_articles, :video_link, :video_url
  end
end
