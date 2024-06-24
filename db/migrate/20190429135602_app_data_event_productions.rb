class AppDataEventProductions < ActiveRecord::Migration[5.0]
  def change
    create_table :app_data_event_productions do |t|                                         
      t.integer :event_id, index: true, foreign_key: true                        
      t.integer :production_id, index: true, foreign_key: true                     
                                                                                
      t.timestamps null: false                                                  
    end   
  end
end
