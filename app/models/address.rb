class Address < ActiveRecord::Base
  has_many :tokens, foreign_key: :address, primary_key: :address
  has_many :organisation_addresses, class_name: 'OrganisationAddress'
  has_many :organisations, through: :organisation_addresses
  has_many :push_notifications
  has_many :activities
  has_many :address_answers, class_name: 'AppData::AddressAnswer'

  validates :address, uniqueness: true

  scope :with_mined_tokens, -> { joins(:tokens).where("tokens.aasm_state = ?", :mined).uniq }

  # used to identify records created by the address owner in the app
  # +salt+:: A string to obfuscate the public address to avoid doxing the wallet owner.
  def address_short_hash salt
    SHA3::Digest::SHA256.new(address + salt.to_s).to_s[0..7]
  end

  # check if this address has any tokens which include the word Publisher
  def is_publisher?
    tokens.map{|t| t.token_type.name}.include?('Publisher')
  end

  # get an OrganisationAddress from a festival_id
  # task::  Scope push notifications at the Organisation level to avoid this.  
  # +festival_id+:: a festival id
  def organisation_address_from_festival_id festival_id
    self.organisation_addresses.where(organisation_id: Festival.find(festival_id).organisation_id).first
  end

  # get an OrganisationAddress settings from a festival_id
  # task::  Scope push notifications at the Organisation level to avoid this.  
  # +festival_id+:: a festival id
  def organisation_address_settings_from_festival_id festival_id
    self.organisation_address_from_festival_id(festival_id).settings
  end
end