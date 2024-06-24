class AddPublishedAtToAppDataEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :app_data_events, :published_at, :datetime
  end
end
