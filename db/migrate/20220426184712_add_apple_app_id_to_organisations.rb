class AddAppleAppIdToOrganisations < ActiveRecord::Migration[6.1]
  def change
    add_column :organisations, :apple_app_id, :string
  end
end
