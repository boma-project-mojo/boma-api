class Feed::TagSerializer < ActiveModel::Serializer
  attributes :id, :name
  type :tag
end