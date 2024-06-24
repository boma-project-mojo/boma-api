class AddIndexToStatsCaches < ActiveRecord::Migration[5.2]
  def change
  	add_index :stats_caches, [:created_at, :stat_type], order: { created_at: :desc }
  end
end
