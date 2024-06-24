class CreateAppDataArticles < ActiveRecord::Migration[5.2]
  def change
    create_table :app_data_articles do |t|
      t.integer :organisation_id
      t.integer :festival_id
      t.integer :user_id
      t.string :title
      t.string :standfirst
      t.string :content
      t.datetime :image_last_updated_at
      t.string :image
      t.string :aasm_state
      t.string :image_name
      t.string :external_link
      t.string :video_link
      t.string :audio

      t.timestamps
    end
  end
end
