class ChangeStatsCachesToOldStatsCaches < ActiveRecord::Migration[5.2]
  def change
    rename_table :stats_caches, :old_stats_caches
  end
end
