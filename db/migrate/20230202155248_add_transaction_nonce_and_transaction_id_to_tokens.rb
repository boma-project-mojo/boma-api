class AddTransactionNonceAndTransactionIdToTokens < ActiveRecord::Migration[7.0]
  def change
    add_column :tokens, :transaction_nonce, :integer
    # add_column :tokens, :transaction_id, :string
  end
end
