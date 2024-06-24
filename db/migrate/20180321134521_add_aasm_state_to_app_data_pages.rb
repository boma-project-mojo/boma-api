class AddAasmStateToAppDataPages < ActiveRecord::Migration[5.0]
  def change
    add_column :app_data_pages, :aasm_state, :string
  end
end
