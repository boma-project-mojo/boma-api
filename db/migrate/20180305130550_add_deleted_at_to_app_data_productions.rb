class AddDeletedAtToAppDataProductions < ActiveRecord::Migration[5.0]
  def change
    add_column :app_data_productions, :deleted_at, :datetime
    add_index :app_data_productions, :deleted_at
  end
end
