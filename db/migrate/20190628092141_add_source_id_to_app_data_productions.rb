class AddSourceIdToAppDataProductions < ActiveRecord::Migration[5.0]
  def change
    add_column :app_data_productions, :source_id, :string
  end
end
