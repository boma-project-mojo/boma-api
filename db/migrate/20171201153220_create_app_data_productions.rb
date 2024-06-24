class CreateAppDataProductions < ActiveRecord::Migration[5.0]
  def change
    create_table :app_data_productions do |t|
      t.string :name
      t.text :description
      t.string :image_name
      t.string :couch_id

      t.timestamps
    end
  end
end
