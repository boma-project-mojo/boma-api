class AddCommunityEventsFlagToFestivals < ActiveRecord::Migration[5.0]
  def change
    add_column :festivals, :community_events_enabled, :boolean
  end
end
