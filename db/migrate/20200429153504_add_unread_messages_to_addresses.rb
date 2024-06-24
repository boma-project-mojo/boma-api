class AddUnreadMessagesToAddresses < ActiveRecord::Migration[5.2]
  def change
    add_column :addresses, :unread_push_notifications, :integer, default: 0
  end
end
