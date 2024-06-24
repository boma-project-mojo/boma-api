class RemoveFilterDayFormatVersionFromFestivals < ActiveRecord::Migration[7.0]
  def change
    remove_column :festivals, :filter_day_format_version
  end
end
