class AddFestivalIdToMessages < ActiveRecord::Migration[5.0]
  def change
    add_column :messages, :festival_id, :string
    add_index :messages, :festival_id
  end
end
