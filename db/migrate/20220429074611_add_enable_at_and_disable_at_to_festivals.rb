class AddEnableAtAndDisableAtToFestivals < ActiveRecord::Migration[6.1]
  def change
    add_column :festivals, :enable_festival_mode_at, :datetime
    add_column :festivals, :disable_festival_mode_at, :datetime
  end
end
