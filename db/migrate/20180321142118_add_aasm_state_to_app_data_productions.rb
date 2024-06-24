class AddAasmStateToAppDataProductions < ActiveRecord::Migration[5.0]
  def change
    add_column :app_data_productions, :aasm_state, :string
  end
end
