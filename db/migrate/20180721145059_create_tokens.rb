class CreateTokens < ActiveRecord::Migration[5.0]
  def change
    create_table :tokens do |t|
      t.string :festival_id
      t.string :address
      t.boolean :was_validated, default: false
      t.string :eth_transaction

      t.timestamps
    end
    add_index :tokens, :festival_id
  end
end
