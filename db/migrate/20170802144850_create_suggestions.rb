class CreateSuggestions < ActiveRecord::Migration[5.0]
  def change
    create_table :suggestions do |t|
      t.text :suggestion

      t.timestamps
    end
  end
end
