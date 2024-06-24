class AddAppVersionToAddresses < ActiveRecord::Migration[5.2]
  def change
    add_column :addresses, :app_version, :string
  end
end
