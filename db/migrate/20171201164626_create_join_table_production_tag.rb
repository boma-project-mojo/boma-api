class CreateJoinTableProductionTag < ActiveRecord::Migration[5.0]
  def change
    create_join_table :productions, :tags, table_name: :app_data_productions_tags do |t|
      # t.index [:production_id, :tag_id]
      # t.index [:tag_id, :production_id]
    end
  end
end
