class AddScheduleModalTypeToFestivals < ActiveRecord::Migration[5.2]
  def change
    add_column :festivals, :schedule_modal_type, :string
  end
end
