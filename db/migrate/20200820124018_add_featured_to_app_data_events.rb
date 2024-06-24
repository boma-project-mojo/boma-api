class AddFeaturedToAppDataEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :app_data_events, :featured, :boolean
  end
end
