class AppData::EventSerializer < ActiveModel::Serializer
  attributes :id, :start_time, :end_time, :image_name, :aasm_state, :can_update, :event_type, :name, :description, :image_thumb, :image_medium, :creator_has_publisher_token, :external_link, :audio_stream, :private_event, :address, :featured, :ticket_link
  type :event
  belongs_to :production
  belongs_to :venue
  belongs_to :festival
  has_many :production_tags

  has_many :productions

  def can_update
    AppData::EventPolicy.new(current_user, object).update?
  end

  def creator_has_publisher_token
    Address.find_by_address(object.wallet_address).is_publisher? rescue nil
  end

  def address
    object.address.address rescue nil
  end
end
