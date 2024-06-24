class CreateAppDataUploads < ActiveRecord::Migration[5.2]
  def change
    create_table :app_data_uploads do |t|
      t.string :upload_type
      t.string :aasm_state
      t.string :processed_url
      t.string :original_url
      t.string :uploadable_id
      t.string :uploadable_type

      t.timestamps
    end
  end
end
