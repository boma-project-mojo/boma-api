class AddDataVersionToFestivals < ActiveRecord::Migration[5.2]
  def change
    add_column :festivals, :data_structure_version, :string, default: 'v2'

    Festival.all.each do |f|
    	f.update! data_structure_version: 'v1'
    end
  end
end
