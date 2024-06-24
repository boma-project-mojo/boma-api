class AddFeedbackEnabledToFestivals < ActiveRecord::Migration[7.0]
  def change
    add_column :festivals, :feedback_enabled, :boolean, default: true
  end
end
