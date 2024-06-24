class CreateMessages < ActiveRecord::Migration[5.0]
  def change
    create_table :messages do |t|
      t.string :subject
      t.string :body
      t.string :topic
      t.string :pushed_state
      t.string :sound
      t.datetime :sent_at

      t.timestamps
    end
  end
end
