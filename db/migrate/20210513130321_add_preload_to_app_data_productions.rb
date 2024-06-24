class AddPreloadToAppDataProductions < ActiveRecord::Migration[5.2]
  def change
    add_column :app_data_productions, :preload, :boolean
  end
end
