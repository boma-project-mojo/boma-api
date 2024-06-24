class AddCommunityArticlesEnabledToFestival < ActiveRecord::Migration[5.2]
  def change
  	add_column :festivals, :community_articles_enabled, :boolean
  end
end
