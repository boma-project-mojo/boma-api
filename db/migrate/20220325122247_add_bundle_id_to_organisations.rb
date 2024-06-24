class AddBundleIdToOrganisations < ActiveRecord::Migration[6.1]
  def change
    add_column :organisations, :bundle_id, :string
  end
end
