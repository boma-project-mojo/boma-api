class CreateTokenTypes < ActiveRecord::Migration[5.0]
  def change
    create_table :token_types do |t|
      t.string :contract_address
      t.string :festival_id
      t.string :name
      t.string :image_base64

      t.timestamps
    end
  end
end
