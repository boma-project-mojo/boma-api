class AddCreatedByToAppDataProductions < ActiveRecord::Migration[5.0]
  def change
    add_column :app_data_productions, :created_by, :string
    add_index :app_data_productions, :created_by

    AppData::Production.all.each{|p| p.created_by = 1; p.save(validations: false)}
  end
end
