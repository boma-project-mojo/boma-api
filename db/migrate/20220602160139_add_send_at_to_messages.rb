class AddSendAtToMessages < ActiveRecord::Migration[6.1]
  def change
    add_column :messages, :send_at, :datetime
  end
end
