class AddUseProductionNameForEventsToFestivals < ActiveRecord::Migration[5.0]
  def change
    add_column :festivals, :use_production_name_for_event_name, :boolean, :default => true
  end
end
