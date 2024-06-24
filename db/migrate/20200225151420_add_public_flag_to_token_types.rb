class AddPublicFlagToTokenTypes < ActiveRecord::Migration[5.2]
  def change
    add_column :token_types, :is_public, :boolean, :default => false
  end
end
