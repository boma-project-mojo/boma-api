class AddAudioStreamToAppDataEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :app_data_events, :audio_stream, :boolean, default: false
  end
end
