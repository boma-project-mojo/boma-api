class AddMetaToAppDataProductions < ActiveRecord::Migration[6.1]
  def change
    add_column :app_data_productions, :meta, :json
  end
end
