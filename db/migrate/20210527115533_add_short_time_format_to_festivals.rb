class AddShortTimeFormatToFestivals < ActiveRecord::Migration[5.2]
  def change
    add_column :festivals, :short_time_format, :string, default: "%a %H:%M"
  end
end
