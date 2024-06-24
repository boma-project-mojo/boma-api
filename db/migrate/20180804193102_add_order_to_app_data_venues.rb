class AddOrderToAppDataVenues < ActiveRecord::Migration[5.0]
  def change
    add_column :app_data_venues, :list_order, :integer
  end
end
