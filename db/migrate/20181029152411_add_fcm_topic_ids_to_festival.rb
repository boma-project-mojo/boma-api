class AddFcmTopicIdsToFestival < ActiveRecord::Migration[5.0]
  def change
    add_column :festivals, :fcm_topic_id, :string
  end
end
