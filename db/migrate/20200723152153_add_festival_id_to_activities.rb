class AddFestivalIdToActivities < ActiveRecord::Migration[5.2]
  def change
    add_column :activities, :festival_id, :integer
  end
end
