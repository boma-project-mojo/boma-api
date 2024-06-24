class CreateFestivals < ActiveRecord::Migration[5.0]
  def change
    create_table :festivals do |t|
      t.string :name
      t.datetime :start_date
      t.datetime :end_date

      t.timestamps
    end
  end
end
