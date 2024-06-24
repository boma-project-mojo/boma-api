class Feed::EventSerializer < ActiveModel::Serializer
  attributes :id, :start_time, :end_time, :filter_day, :name, :description, :image_thumb, :image_small_thumb, :date_string_start, :date_string_end
  type :event
  belongs_to :production
  belongs_to :venue

  def production
    object.production.id
  end

  def venue
    object.venue.id
  end

  def image_thumb
    self.object.production.image_thumb
  end

  def image_small_thumb
    self.object.production.image_small_thumb
  end

end