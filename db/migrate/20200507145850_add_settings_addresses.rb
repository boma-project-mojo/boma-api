class AddSettingsAddresses < ActiveRecord::Migration[5.2]
  def change
    add_column :addresses, :settings, :json  	
  end
end