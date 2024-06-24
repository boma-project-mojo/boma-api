class TokenType < ApplicationRecord
  attr_accessor :festival_couchdb_name

  include Couchdb

  has_many :tokens
  belongs_to :organisation, optional: true
  belongs_to :festival, optional: true

  # Must have festival or organisation relationships
  validates :festival_id, :presence => {message: "can't be blank if organisation_id isn't present"}, unless: :organisation_id
  validates :organisation_id, :presence => {message: "can't be blank if festival_id isn't present"}, unless: :festival_id
  validates :organisation, presence: true
  validates :contract_address, presence: true
  validates :chain, presence: true

  after_commit :couch_update_or_create, on: [:create, :update, :destroy]

  def published?
    true
  end

  def deleted?
    false
  end

  def preview?
    false
  end

  # The following attributes are used when validating tokens using the Space and Place 
  # methodlogy.  
  def event_start_time
    festival.start_date rescue nil
  end

  def event_end_time
    festival.end_date rescue nil
  end

  def event_center_lat
    festival.center_lat rescue nil
  end

  def event_center_long
    festival.center_long rescue nil
  end

  def event_radius
    festival.location_radius rescue nil
  end

  def to_couch_data
    data = {
      name: name,
      image_base64: image_base64,
      event_start_time: event_start_time,
      event_end_time: event_end_time,
      event_center_lat: event_center_lat,
      event_center_long: event_center_long,
      event_radius: event_radius,
      contract_address: contract_address,
      is_public: is_public,
      festival_id: festival_id
    }
  end
end