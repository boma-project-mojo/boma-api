class AddTokenTypeIdToTokens < ActiveRecord::Migration[5.0]
  def change
    add_column :tokens, :token_type_id, :string
  end
end
