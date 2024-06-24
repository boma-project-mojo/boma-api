class Token < ApplicationRecord
  attr_accessor :client_id

  belongs_to :token_type
  belongs_to :festival, optional: true
  delegate :organisation, :to => :festival

  validates :token_type, :uniqueness => {:scope => [:address], message: " - a relationship already exists between this address and this token_type"}, unless: :address_is_nil?

  def transaction_nonce_is_unique_for_this_organisation
    unless self.transaction_nonce === nil or Token.where(festival_id: self.organisation.festivals.ids).where(transaction_nonce: self.transaction_nonce).where.not(id: self.id).count === 0
      self.errors.add(:transaction_nonce, " must be unique per organisation")
    end
  end
  validate :transaction_nonce_is_unique_for_this_organisation
  
  # Check that the address used for claiming the token is a valid eth address
  def address_is_valid
    begin
      address = Eth::Address.new(self.address)
      unless address.valid? 
        self.errors.add(:address, " is invalid")
      end 
    rescue
      self.errors.add(:address, " is invalid")
    end    
  end
  validate :address_is_valid, unless: :address_is_nil?

  def address_is_nil?
    self.address === nil
  end

  include AASM

  aasm do    
    state :initialized, :initial => true
    state :queued
    state :mining
    state :mined
    state :failed

    event :claim do
      transitions :from => [:initialized], :to => :queued
    end 

    event :mine do
      transitions :from => [:queued], :to => :mining
    end 

    event :mined do
      transitions :from => [:mining], :to => :mined
    end 
  end

  before_create :set_token_hash

  # This token hash is used when distributing tokens to redeem by link
  # it provides a single use nonce that can be used to claim a Token
  def set_token_hash
    self.token_hash = SecureRandom.hex
  end
end
