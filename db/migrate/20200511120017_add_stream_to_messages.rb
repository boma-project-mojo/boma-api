class AddStreamToMessages < ActiveRecord::Migration[5.2]
  def change
    add_column :messages, :stream, :string
  end
end
