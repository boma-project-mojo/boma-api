class User < ApplicationRecord
  attr_accessor :current_festival

  include AASM

  aasm do
    state :draft, :initial => true
    state :invited
    state :active
    state :revoked

    event :invite do
      transitions :from => [:draft, :invited], :to => :invited
    end

    event :active do
      transitions :from => [:invited], :to => :active
    end

    event :activate do
      transitions :from => [:active, :invited], :to => :revoked
    end
  end

  after_create :assign_default_role

  validates :name, presence: true

  def assign_default_role
    self.add_role(:newuser) if self.roles.blank?
  end
  
  rolify

  before_save :ensure_authentication_token

  def ensure_authentication_token
    if authentication_token.blank?
      self.authentication_token = generate_authentication_token
    end
  end    

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :lockable, :rememberable, :trackable, :validatable, :recoverable

  has_many :messages, :foreign_key => "created_by"

  def can_edit_venues
    roles.where(name: :editor, resource_type: 'AppData::Venue').map(&:resource_id)
  end

  def can_edit_festivals
    roles.where(name: :admin, resource_type: 'Festival').map(&:resource_id)
  end

  def can_edit_organisations
    roles.where(name: :admin, resource_type: 'Organisation').map(&:resource_id)
  end

  def can_index_festivals
    if(self.has_role?(:admin, :any))
      can_edit_festivals = self.can_edit_festivals.uniq
    else
      can_edit_venues = self.can_edit_venues
      AppData::Venue.where(id: can_edit_venues).map(&:festival_id).uniq
    end
  end

  def can_index_organisations
    # if(self.has_role?(:admin, Organisation))
      can_edit_organisations = self.can_edit_organisations.uniq
    # end
  end

  def can_edit_articles_for_organisation organisation_id
    if(self.has_role?(:admin, Organisation.find(organisation_id)))
      true
    else
      festival_ids = Organisation.find(organisation_id).festivals.collect(&:id)
      # Check that the can_edit_festivals array of ids includes at least one of the festival_ids for this organisation
      (self.can_edit_festivals & self.festival_ids).any?
    end
  end

  def send_invite festival
    token = set_reset_password_token
    UserMailer.invite(self, token, festival).deliver_now
    invite!
  end

  private

    def set_reset_password_token
      raw, enc = Devise.token_generator.generate(self.class, :reset_password_token)

      self.reset_password_token   = enc
      self.reset_password_sent_at = Time.now.utc
      save!(validate: false)
      raw
    end

    def generate_authentication_token
      loop do
        token = Devise.friendly_token
        break token unless User.where(authentication_token: token).first
      end
    end
end