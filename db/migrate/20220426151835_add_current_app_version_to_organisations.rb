class AddCurrentAppVersionToOrganisations < ActiveRecord::Migration[6.1]
  def change
    add_column :organisations, :current_app_version, :string
  end
end
