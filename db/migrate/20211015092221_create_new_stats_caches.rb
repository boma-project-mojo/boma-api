class CreateNewStatsCaches < ActiveRecord::Migration[5.2]
  def change
    create_table :stats_caches do |t|
      t.string :period_length
      t.integer :festival_id
      t.jsonb :period_data
      t.timestamps
    end
  end
end
