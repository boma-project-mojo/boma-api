class AddAttrsToAppDataProductions < ActiveRecord::Migration[5.0]
  def change
    add_column :app_data_productions, :external_link, :string
    add_column :app_data_productions, :video_link, :string
    add_column :app_data_productions, :short_description, :string, before: :description, default: ""
  end
end
