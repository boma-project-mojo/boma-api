class CreateAppDataQuestions < ActiveRecord::Migration[7.0]
  def change
    create_table :app_data_questions do |t|
      t.integer :survey_id
      t.string :question_text
      t.string :question_type

      t.timestamps
    end
  end
end
