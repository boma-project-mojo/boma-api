class Feed::ProductionSerializer < ActiveModel::Serializer
  attributes :id, :last_updated_timestamp, :name, :description, :image_name, :external_link, :video_link
  type :production
  has_many :events
  has_many :tags

  def last_updated_timestamp
    object.updated_at.to_i
  end

  def image_name
    object.image.url
  end

  def events
    object.events.map{|e| e.id}
  end

  def tags
    object.tags.map{|t| t.id}
  end  

end
