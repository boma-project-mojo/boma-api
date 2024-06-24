class AddAasmStateToAppDataEvents < ActiveRecord::Migration[5.0]
  def change
    add_column :app_data_events, :aasm_state, :string
  end
end
