class CreateAppDataAnswers < ActiveRecord::Migration[7.0]
  def change
    create_table :app_data_answers do |t|
      t.integer :question_id
      t.string :answer_text
      t.string :answer_type

      t.timestamps
    end
  end
end
