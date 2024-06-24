class RemoveTelegramChatIdFromFestivals < ActiveRecord::Migration[7.0]
  def change
    remove_column :organisations, :telegram_chat_id
  end
end
