class AppData::TagSerializer < ActiveModel::Serializer
  attributes :id, :name, :aasm_state, :tag_type, :description, :festival_id, :organisation_id
  type :tag
  has_many :productions
end
