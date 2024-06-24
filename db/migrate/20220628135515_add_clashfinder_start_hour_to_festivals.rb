class AddClashfinderStartHourToFestivals < ActiveRecord::Migration[6.1]
  def change
    add_column :festivals, :clashfinder_start_hour, :integer, default: 5
  end
end
