class AddTimezoneToFestivals < ActiveRecord::Migration[5.0]
  def change
    add_column :festivals, :timezone, :string
  end
end
