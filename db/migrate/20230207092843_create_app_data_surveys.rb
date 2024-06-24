class CreateAppDataSurveys < ActiveRecord::Migration[7.0]
  def change
    create_table :app_data_surveys do |t|
      t.string :name
      t.integer :surveyable_id
      t.string :surveyable_type
      t.datetime :enable_at
      t.datetime :disable_at

      t.timestamps
    end
  end
end
