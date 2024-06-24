class AddExternalLinkToAppDataEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :app_data_events, :external_link, :string
  end
end
