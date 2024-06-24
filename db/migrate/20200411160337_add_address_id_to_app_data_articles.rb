class AddAddressIdToAppDataArticles < ActiveRecord::Migration[5.2]
  def change
  	add_column :app_data_articles, :address_id, :integer
  end
end
