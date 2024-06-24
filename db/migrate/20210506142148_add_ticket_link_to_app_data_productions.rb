class AddTicketLinkToAppDataProductions < ActiveRecord::Migration[5.2]
  def change
    add_column :app_data_productions, :ticket_link, :string
  end
end
