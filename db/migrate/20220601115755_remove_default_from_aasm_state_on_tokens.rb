class RemoveDefaultFromAasmStateOnTokens < ActiveRecord::Migration[6.1]
  def change
    change_column_default(:tokens, :aasm_state, nil)
  end
end
