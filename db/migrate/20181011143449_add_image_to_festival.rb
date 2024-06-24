class AddImageToFestival < ActiveRecord::Migration[5.0]
  def change
    add_column :festivals, :image, :string
  end
end
