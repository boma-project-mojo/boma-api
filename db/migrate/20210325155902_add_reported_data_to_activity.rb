class AddReportedDataToActivity < ActiveRecord::Migration[5.2]
  def change
    add_column :activities, :reported_data, :json
    add_column :activities, :organisation_id, :integer
  end
end
