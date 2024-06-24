class AddEventIdToMessages < ActiveRecord::Migration[5.2]
  def change
    add_column :messages, :event_id, :integer
  end
end
