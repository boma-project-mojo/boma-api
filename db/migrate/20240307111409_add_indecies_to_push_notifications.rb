class AddIndeciesToPushNotifications < ActiveRecord::Migration[7.0]
  def change
    add_index :push_notifications, [:created_at, :festival_id]
  end
end
