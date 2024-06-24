class AddIndexForAddressIdFestivalIdAndActivityTypeToActivities < ActiveRecord::Migration[7.0]
  def change
    add_index :activities, [:address_id, :festival_id, :activity_type], name: 'by_address_festival_and_activity_type'
  end
end