class AppData::PageSerializer < ActiveModel::Serializer
  attributes :id, :name, :content, :image_name, :image_thumb, :aasm_state, :image_medium
  type :page
end