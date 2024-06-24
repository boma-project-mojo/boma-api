class AddListOrderToFestivals < ActiveRecord::Migration[5.2]
  def change
    add_column :festivals, :list_order, :integer
  end
end
