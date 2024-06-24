class AddRequireImagesFlagsToAppDataFestivals < ActiveRecord::Migration[6.1]
  def change
    add_column :festivals, :require_production_images, :boolean, default: true
    add_column :festivals, :require_venue_images, :boolean, default: true
  end
end
