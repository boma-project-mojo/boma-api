class AddTelegramChatIdToOrganisations < ActiveRecord::Migration[7.0]
  def change
    add_column :organisations, :telegram_chat_id, :string
    add_column :organisations, :slack_channel_name, :string
  end
end
