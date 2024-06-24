class AppData::Person < AppData::Base

  # Future:  Use wallet and token_type to join Person and Festival 
  validates :festival_id, :presence => {message: "can't be blank"}

  include AASM

  aasm do 
    state :draft, :initial => true
    state :published

    event :publish do
      transitions :from => [:draft], :to => :published
    end

    event :unpublish do
      transitions :from => [:published], :to => :draft
    end
  end

  after_commit :couch_update_or_create, on: [:create, :update, :destroy]

  belongs_to :festival

  acts_as_paranoid

  def to_couch_data

    data = {
      festival_id: festival_id,
      firstname: firstname,
      surname: surname,
      email: email,
      company: company,
      job_title: job_title,
      aasm_state: aasm_state
    }

  end

  def couch_update_or_create is_callback = false
    super

    unless is_callback
      
    end
  end


end
