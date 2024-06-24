class PushNotification < ApplicationRecord
	belongs_to :messagable, polymorphic: true
	belongs_to :address
  belongs_to :organisation, optional: true
  belongs_to :festival, optional: true

  acts_as_paranoid

	validates :subject, presence: true
	validates :body, presence: true

  # In the case of PushNotifications which relate to an Event, Article or Message that
  # has a specific Festival Context we require the festival_id so that the app can handle
  # switching context when handling the notification payload.  
  validates :festival_id, presence: true, if: :requires_festival_app_context?
  def requires_festival_app_context?
    if self.messagable_type === "Message" and self.festival_id === nil
      errors.add(:festival_id, "can't be blank")
    elsif self.messagable_type === "AppData::Article"
      if self.organisation_id === nil && self.festival_id === nil
        errors.add(:festival_id, "can't be blank")
      end
    elsif self.messagable_type === "AppData::Event" and self.festival_id === nil
      errors.add(:festival_id, "can't be blank")
    end
  end

  validates :messagable_id, :uniqueness => {:scope => [:address_id], message: "You can't create multiple push notifications for the same messagable_id and address_id"}

  scope :drafts, -> { where(pushed_state: :draft) }
  scope :approved, -> { where(pushed_state: :approved) }

  def article
    messagable if messagable_type == 'AppData::Article'
  end

  def event
    messagable if messagable_type == 'AppData::Event'
  end

  include AASM

  aasm column: :pushed_state do 
    state :draft, :initial => true
    state :approved
    state :sent
    state :cancelled
    state :failed

    event :approve do
      transitions :from => [:draft], :to => :approved
    end

    event :send_notification do
      transitions :from => [:approved], :to => :sent
    end

    event :fail do
      transitions :from => [:approved], :to => :failed
    end

    event :cancel do
      transitions :from => [:approved, :draft], :to => :cancelled
    end
  end

  def organisation_address
    self.address.organisation_addresses.find_by_organisation_id(self.festival.organisation_id)
  end

  def fcm_token
    self.address.organisation_addresses.find_by_organisation_id(self.festival.organisation_id).fcm_token rescue nil
  end
end