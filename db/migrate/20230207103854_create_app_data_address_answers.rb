class CreateAppDataAddressAnswers < ActiveRecord::Migration[7.0]
  def change
    create_table :app_data_address_answers do |t|
      t.integer :address_id
      t.integer :question_id
      t.integer :answer_id

      t.timestamps
    end
  end
end
