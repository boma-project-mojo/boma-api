class Message < ApplicationRecord
  attr_accessor :address

	belongs_to :article, class_name: 'AppData::Article', optional: true
  belongs_to :event, class_name: 'AppData::Event', optional: true
  belongs_to :token_type, optional: true
  belongs_to :festival
  belongs_to :address, optional: true

  acts_as_paranoid

	validates :subject, presence: true
	validates :body, presence: true
	# validates :topic, presence: true
	validates :pushed_state, :inclusion=> { :in => ["draft", "approved", "sent", "removed"] }
  validates :created_by, presence: true
  validates :stream, presence: true
  validates :address_id, presence: {message: "can't be found."}, if: :has_address

  # check the model has an address
  def has_address
    !self.address.nil?
  end

  validate do
    unless attribute_was(:pushed_state) == pushed_state
      case attribute_was :pushed_state
      #from
      when "draft"
        #to
        errors.add(:pushed_state, "cannot transition from #{attribute_was :pushed_state} to #{pushed_state}") unless ["approved"].include?(pushed_state)
      when "approved"
        errors.add(:pushed_state, "cannot transition from #{attribute_was :pushed_state} to #{pushed_state}") unless ["sent"].include?(pushed_state)
      when "sent"
        errors.add(:pushed_state, "cannot transition from #{attribute_was :pushed_state} to #{pushed_state}") unless ["removed"].include?(pushed_state)
      end
    end
  end

	scope :sent, -> { where(pushed_state: :sent) }
	scope :draft, -> { where(pushed_state: :draft) }
	scope :approved, -> { where(pushed_state: :approved) }
	scope :approved_or_published, -> { where(pushed_state: [:approved, :sent])}
  scope :published, -> { where(pushed_state: :sent).order('sent_at DESC') }

	belongs_to :user, foreign_key: :created_by

  # check the message pushed_state is :draft
  def draft?
    pushed_state === :draft
  end

  # returns the counts of various pushed_states (:draft :approved, :sent, :removed) for a message.  
  # these are displayed in the boma admin section.  
  def message_status
    if self.article_id
      ms = PushNotification.where(body: self.body).where(messagable_id: self.article_id).group(:pushed_state).count
    elsif self.event_id
      ms = PushNotification.where(body: self.body).where(messagable_id: self.event_id).group(:pushed_state).count
    elsif 
      ms = PushNotification.where(body: self.body).where(messagable_id: self.id).group(:pushed_state).count
    end
    ms
  end

  # Parse the message body and replace any links with anchors to allow links included in push notification bodies 
  # to be clicked in the app.  
  def body_with_anchors
    regexp = /\b((?:https?:\/\/|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}\/?)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s\`!()\[\]{};:\'\".,<>?«»“”‘’]))/i
    body.gsub(regexp){|url| "<a target='_blank' href='#{url}'>#{url}</a>"}.html_safe
  end
end
