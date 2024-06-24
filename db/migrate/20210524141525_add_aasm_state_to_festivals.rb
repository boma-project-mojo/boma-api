class AddAasmStateToFestivals < ActiveRecord::Migration[5.2]
  def change
    add_column :festivals, :aasm_state, :string
  end
end
