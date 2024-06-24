class AddRequireDescriptionToFestivals < ActiveRecord::Migration[7.0]
  def change
    add_column :festivals, :require_description, :boolean, default: true
  end
end
