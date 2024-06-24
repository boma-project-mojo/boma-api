class AddImageBase64ToToken < ActiveRecord::Migration[5.0]
  def change
    add_column :tokens, :image_base64, :string
  end
end
