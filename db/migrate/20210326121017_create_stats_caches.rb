class CreateStatsCaches < ActiveRecord::Migration[5.2]
  def change
    create_table :stats_caches do |t|
      t.string :period_length
      t.string :stat_type
      t.integer :cumulative_total
      t.integer :period_total
      t.integer :festival_id
      t.jsonb :meta

      t.timestamps
    end
  end
end
