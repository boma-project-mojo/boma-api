class AddTicketLinkToAppDataEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :app_data_events, :ticket_link, :string
  end
end
