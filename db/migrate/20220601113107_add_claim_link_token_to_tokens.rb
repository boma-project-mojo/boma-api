class AddClaimLinkTokenToTokens < ActiveRecord::Migration[6.1]
  def change
    add_column :tokens, :nonce, :string
  end
end
