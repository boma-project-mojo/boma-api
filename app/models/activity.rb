class Activity < ApplicationRecord
	belongs_to :address
	belongs_to :push_notification, optional: true

	validates :activity_type, :presence => {message: "can't be blank"}, :uniqueness => {:scope => [:festival_id, :address_id]}, unless: -> {:is_legacy_app_ping?}

  # In the new implementation Activity is recorded in one single record per Festival per Address.  
  #
  # In legacy implementations of the app the 'Open open' metric was recorded in an Activity record
  # per open.  This method is used to negate the uniqueness validation above.  
	def is_legacy_app_ping 
		activity_type === 'app_ping'
	end
end
