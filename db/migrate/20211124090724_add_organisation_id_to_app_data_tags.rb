class AddOrganisationIdToAppDataTags < ActiveRecord::Migration[5.2]
  def change
    add_column :app_data_tags, :organisation_id, :integer
  end
end
