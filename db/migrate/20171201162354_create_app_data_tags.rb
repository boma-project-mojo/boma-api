class CreateAppDataTags < ActiveRecord::Migration[5.0]
  def change
    create_table :app_data_tags do |t|
      t.string :name
      t.string :couch_id

      t.timestamps
    end
  end
end
