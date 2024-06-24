class AddAasmStateToToken < ActiveRecord::Migration[5.0]
  def change
    add_column :tokens, :aasm_state, :string, :default => 'mining'
  end
end
