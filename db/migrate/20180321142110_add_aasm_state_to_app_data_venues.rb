class AddAasmStateToAppDataVenues < ActiveRecord::Migration[5.0]
  def change
    add_column :app_data_venues, :aasm_state, :string
  end
end
