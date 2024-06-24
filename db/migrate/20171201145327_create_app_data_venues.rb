class CreateAppDataVenues < ActiveRecord::Migration[5.0]
  def change
    create_table :app_data_venues do |t|
      t.string :name
      t.string :lat
      t.string :long
      t.string :image_name
      t.string :image_name_small
      t.string :venue_type
      t.text :description
      t.string :couch_id

      t.timestamps
    end
  end
end
