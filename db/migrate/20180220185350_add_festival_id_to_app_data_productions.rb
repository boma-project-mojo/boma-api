class AddFestivalIdToAppDataProductions < ActiveRecord::Migration[5.0]
  def change
    add_column :app_data_productions, :festival_id, :string
    add_index :app_data_productions, :festival_id
  end
end
