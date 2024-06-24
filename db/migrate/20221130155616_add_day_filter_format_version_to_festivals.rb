class AddDayFilterFormatVersionToFestivals < ActiveRecord::Migration[6.1]
  def change
    add_column :festivals, :filter_day_format_version, :string, default: "v2"

    Festival.all.each do |f|
      f.update! filter_day_format_version: 'v1'
    end
  end
end
