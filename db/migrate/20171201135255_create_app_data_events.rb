class CreateAppDataEvents < ActiveRecord::Migration[5.0]
  def change
    create_table :app_data_events do |t|
      t.datetime :start_time
      t.datetime :end_time
      t.integer :venue_id
      t.string :name
      t.text :description
      t.string :image_name
      t.string :image_name_small
      t.integer :production_id
      t.text :couch_id

      t.timestamps
    end
  end
end
