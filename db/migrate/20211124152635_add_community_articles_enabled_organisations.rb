class AddCommunityArticlesEnabledOrganisations < ActiveRecord::Migration[5.2]
  def change
    add_column :organisations, :community_articles_enabled, :boolean, default: false
  end
end
