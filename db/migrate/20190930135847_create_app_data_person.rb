class CreateAppDataPerson < ActiveRecord::Migration[5.0]
  def change
    create_table :app_data_people do |t|
      t.integer :festival_id
      t.string :email
      t.string :firstname
      t.string :surname
      t.string :company
      t.string :job_title
      t.string :aasm_state
    end
  end
end
