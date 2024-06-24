class TokenSerializer < ActiveModel::Serializer
  attributes :id, :address, :was_validated, :name, :image_base64, :token_type_id, :festival_id, :aasm_state, :event_start_date, :event_end_date, :event_location_radius, :event_center_lat, :event_center_long, :updated_at, :client_id
  type :token
  belongs_to :festival

  def name
    object.token_type.name
  end

  def image_base64
    object.token_type.image_base64
  end

  def token_type_id
    object.token_type.id
  end

  def festival_id
    object.token_type.festival_id
  end

  def event_start_date
    object.token_type.event_start_time 
  end

  def event_end_date
    object.token_type.event_end_time
  end

  def event_center_lat
    object.token_type.event_center_lat
  end

  def event_center_long
    object.token_type.event_center_long
  end

  def event_location_radius
    object.token_type.event_radius
  end
end