class Feed::VenueSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :venue_type, :lat, :long, :image_full_size, :menu, :dietary_requirements
  type :venue

  def image_full_size
    object.image.url
  end
end