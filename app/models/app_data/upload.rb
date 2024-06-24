class AppData::Upload < AppData::Base
	belongs_to :uploadable, polymorphic: true

	include AASM

  scope :audio, -> { where(upload_type: :audio) }
  scope :video, -> { where(upload_type: :video) }

	aasm do 
	  state :draft, :initial => true
	  state :processed
	  state :failed

	  event :process do
	    transitions :from => [:draft, :failed], :to => :processed
	  end

	  event :fail do
	  	transitions :from => [:draft, :failed], :to => :failed
	  end
	end

	after_create :process

	def process
		MediaConverterWorker.perform_async(self.id, self.upload_type)
	end

	def published?
		true
	end

end