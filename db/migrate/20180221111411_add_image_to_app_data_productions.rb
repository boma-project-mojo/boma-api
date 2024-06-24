class AddImageToAppDataProductions < ActiveRecord::Migration[5.0]
  def change
    add_column :app_data_productions, :image, :string
  end
end
