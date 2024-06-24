class AddFestivalIdToSuggestions < ActiveRecord::Migration[5.0]
  def change
    add_column :suggestions, :festival_id, :string
    add_index :suggestions, :festival_id
  end
end
