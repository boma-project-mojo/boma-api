class AddDeletedAtToAddDataArticles < ActiveRecord::Migration[5.2]
  def change
    add_column :app_data_articles, :deleted_at, :datetime
    add_index :app_data_articles, :deleted_at
  end
end
