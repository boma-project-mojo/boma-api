class AddNameToToken < ActiveRecord::Migration[5.0]
  def change
    add_column :tokens, :name, :string
  end
end
