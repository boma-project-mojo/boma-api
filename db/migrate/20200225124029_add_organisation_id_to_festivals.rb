class AddOrganisationIdToFestivals < ActiveRecord::Migration[5.2]
  def change
     add_column :festivals, :organisation_id, :string
  end
end
