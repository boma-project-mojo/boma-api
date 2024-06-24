class ChangeNonceToHashOnTokens < ActiveRecord::Migration[7.0]
  def change
    rename_column :tokens, :nonce, :token_hash
  end
end
