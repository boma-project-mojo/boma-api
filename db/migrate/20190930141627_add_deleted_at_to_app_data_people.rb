class AddDeletedAtToAppDataPeople < ActiveRecord::Migration[5.0]
  def change
    add_column :app_data_people, :deleted_at, :datetime
    add_index :app_data_people, :deleted_at
  end
end
