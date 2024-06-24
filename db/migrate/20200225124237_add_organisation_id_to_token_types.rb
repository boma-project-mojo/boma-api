class AddOrganisationIdToTokenTypes < ActiveRecord::Migration[5.2]
  def change
    add_column :token_types, :organisation_id, :string
  end
end
