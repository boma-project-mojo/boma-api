class AddTelegramStatsChatIdToFestivals < ActiveRecord::Migration[5.2]
  def change
    add_column :festivals, :telegram_stats_chat_id, :string
    add_column :festivals, :telegram_moderators_chat_id, :string
    Festival.find(3).update! telegram_stats_chat_id: ENV['TELEGRAM_STATS_CHAT_ID']
    Festival.find(3).update! telegram_moderators_chat_id: ENV['TELEGRAM_CHAT_ID']
  end
end
