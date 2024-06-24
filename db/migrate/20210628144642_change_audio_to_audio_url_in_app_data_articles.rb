class ChangeAudioToAudioUrlInAppDataArticles < ActiveRecord::Migration[5.2]
  def change
  	rename_column :app_data_articles, :audio, :audio_url
  end
end
