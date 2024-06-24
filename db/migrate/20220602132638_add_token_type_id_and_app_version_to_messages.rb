class AddTokenTypeIdAndAppVersionToMessages < ActiveRecord::Migration[6.1]
  def change
    add_column :messages, :token_type_id, :int
    add_column :messages, :app_version, :string
  end
end
