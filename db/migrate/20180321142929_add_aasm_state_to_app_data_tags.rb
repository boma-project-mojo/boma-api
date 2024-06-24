class AddAasmStateToAppDataTags < ActiveRecord::Migration[5.0]
  def change
    add_column :app_data_tags, :aasm_state, :string
  end
end
