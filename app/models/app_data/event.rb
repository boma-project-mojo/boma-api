class AppData::Event < AppData::Base
  attr_accessor :production_source_ids, :venue_source_id

  validates :name, :presence => {message: "can't be blank"}, if: -> {is_community_event?}
  validates :start_time, :presence => {message: "can't be blank"}, if: -> {
    public_record? or
    is_community_event?
  }
  validates :end_time, :presence => {message: "can't be blank"}, if: -> {
    public_record? and
    !is_community_event?
  }
  validate :end_time_after_start_time, unless: :is_community_event?
  validates :productions, :presence => {message: "can't be blank"}, unless: :is_community_event?
  validate :has_valid_productions, if: -> {
    (
      (is_checking_app_validity and !checking_production_validity) || 
      publishing?
    ) &&
    requires_production?
  }
  validates :venue, :presence => {message: "can't be blank"}, unless: -> {is_virtual_event?}
  validates :festival_id, :presence => {message: "can't be blank"}

  validate :clashing_events

  # Validate that events at the same venue do not occur whilst an event is already 
  # set to take place at that venue (unless `allow_concurrent_events` is set to true on the 
  # related venue).  
  def clashing_events
    if self.venue
      #if the venue is configured to allow concurrent events then disregard this validation
      if self.venue.allow_concurrent_events
        return true
      end

      unless self.aasm_state === "cancelled"
        clashes = self.venue.events
          .where.not(aasm_state: "cancelled")
          .where('end_time > ?', self.start_time)
          .where('start_time < ?', self.end_time)
          .where.not(id: self.id)

        if clashes.length > 0
          self.errors.add(:start_time, " - Event clash!  Only one event can take place at each venue at a time.  The event you're trying to create clashes with #{clashes.map {|c| "#{c.name} (#{c.date_string_start} - #{c.date_string_end})" }.to_sentence}")
        end
      end
    end
  end

  # check that the associated productions pass validation.
  def has_valid_productions
    return if self.deleted?

    valid_productions = productions.map{|p| 
      p.valid_for_app?
    }

    if valid_productions.count == 0
      errors.add(:productions, "at least one.")
    end
    if valid_productions.include? false
      errors.add(:productions, "can't be invalid.")
    end
  end  

  # returns true if the event is transitioning from aasm_state :draft to :published
  def publishing?
    aasm_state_was == 'draft' and aasm_state == 'published'
  end

  # validate the end time is after the start time
  def end_time_after_start_time
    if(self.end_time and self.start_time)
      unless(self.end_time > self.start_time)
        errors.add(:end_time, "must be after start time")
      end
    end
  end

	include AASM

	aasm do 
	  state :draft, :initial => true
	  state :published
    state :cancelled

	  event :publish do
	    transitions :from => [:draft], :to => :published, after: :set_published_at
	  end

	  event :unpublish do
	    transitions :from => [:published], :to => :draft
	  end

    event :cancel do
      transitions :from => [:published], :to => :cancelled
    end
	end

	# has_paper_trail
	acts_as_paranoid

  # Called manually in AdminApi::V1::EventsController#create to ensure events created after a production is published are
  # given the same aasm_state as the production.  
  def mirror_production_published_state
    unless self.aasm_state == 'cancelled'
      if self.production.aasm_state == 'published' and self.aasm_state != 'published'
        self.publish!
      end
      if self.production.aasm_state == 'draft' and self.aasm_state != 'draft'
        self.unpublish!
      end
      if self.production.aasm_state == 'locked' and self.aasm_state != 'draft'
        self.unpublish!
      end
    end
  end

  after_commit :couch_update_or_create, on: [:create, :update, :destroy]
  after_commit :create_draft_push_notifications_for_creator_and_all_app_users
  after_commit :notify_moderators_about_a_new_submission, on: [:create]
  after_commit :notify_moderators_about_a_new_submission, on: [:create]
  
  belongs_to :festival
	belongs_to :venue, optional: true

	has_many :event_productions, -> { order(created_at: :asc) }
  has_many :productions, through: :event_productions

  has_many :taggings, :foreign_key => 'taggable_id'
  # Tags for this event
  has_many :event_tags, -> { where(tag_type: 'event') }, through: :taggings, autosave: false, source: 'tag'
  # All the tags which belong to associated productions
  has_many :production_tags, through: :productions, source: :tags
  
	attr_accessor :venue_name, :day, :filter_day

  belongs_to :owner, :class_name => "User", :foreign_key => "created_by", optional: true

  scope :published_or_cancelled, -> {where(aasm_state: [:published, :cancelled])}
  scope :community_events, -> { where(event_type: :community_event) }
  scope :virtual_events, -> { where(virtual_event: true) }

  # find a related address
  def address
    Address.find_by_address(self.wallet_address)
  end

  # get the address_id for this event (only provided for community events)
  def address_id
    address.id
  end

  # check this model is owned by the provided user
  # +user+:: An ActiveRecord User object 
  def owned_by? user
    owner == user
  end

  # check that this event requires a production
  # (all events apart from community events must have a production)
  def requires_production? 
    return is_community_event? ? false : true
  end

  # check this event has event_type :community_event
  def is_community_event?
    self.event_type == 'community_event'
  end

  def is_virtual_event?
    self.event_type === "virtual" or self.virtual_event === true
  end

  # check that the audio_stream attribute is set to true
  def is_audio_stream?
    self.audio_stream === true
  end

  mount_uploader :image, ImageUploader

  ##    The Production/Event models are setup to allow flexiblity in including
  ##    Event specific name, description, short_description, 
  ##    external_link, ticket_link and images (and related time stamps used for bundling logic)
  ##
  ##    Where an attribute is set on the Event model it takes precedence over the
  ##    same attribute on the Production model.  
  ##
  ##    Where an attribute is not set on the Event model the value from the related production is used.  
  ##    
  ##    The following methods relate to the logic to achieve this.  

  # get the associated Production
  # this is used to get an image and description for the event if they
  # are not set on the Event.  
  def production
    # if the production_id attribute is populated 
      # return that production
    # else
      # return the first production (which is the one used for images / descriptions etc)
    read_attribute(:production_id).blank? ? productions.first : AppData::Production.find(production_id) rescue nil
  end

  # get the image thumb
  def image_thumb
    # if the Event has an image
      # return that image
    # else
      # return the Production image
    image = self.image.thumb.url.blank? ? production.image : self.image rescue nil
    unless image.nil? or image.thumb.nil? or image.thumb.url.nil?
      image.thumb.url
    end
  end

  # get the image small thumb
  def image_small_thumb
    # if the Event has an image
      # return that image
    # else
      # return the Production image
    image = self.image.small_thumb.url.blank? ? production.image : self.image rescue nil
    unless image.nil? or image.small_thumb.nil? or image.small_thumb.url.nil?
      image.small_thumb.url
    end
  end

  # get the image loader
  def image_loader
    # if the Event has an image
      # return that image
    # else
      # return the Production image
    image = self.image.loader.url.blank? ? production.image : self.image rescue nil
    unless image.nil? or image.loader.nil? or image.loader.url.nil?
      Base64.strict_encode64(image.loader.read) rescue nil
    end
  end

  # get the image_bundled_at datetime
  def image_bundled_at
    # if the Event has an image_bundled_at
      # return that image_bundled_at
    # else
      # return the Production image_bundled_at
    read_attribute(:image_bundled_at).blank? ? production.image_bundled_at : read_attribute(:image_bundled_at) rescue nil
  end  

  # get the image_last_updated_at datetime
  def image_last_updated_at
    # if the Event has an image_last_updated_at
      # return that image_last_updated_at
    # else
      # return the Production image_last_updated_at
    read_attribute(:image_last_updated_at).blank? ? production.image_last_updated_at : read_attribute(:image_last_updated_at) rescue nil
  end

  # get the name
	def name
    # if this is a community event 
      # return the Event name
    # else 
      # if the festival attribute use_production_name_for_event_name is true
        # return the Production name
      # else
        # if the event name is blank
          # return the Production name
        # otherwise
          # return the Event name
    if is_community_event?
      read_attribute(:name).blank? ? production.name : read_attribute(:name) rescue nil
    else
      if self.festival && self.festival.use_production_name_for_event_name and self.production
        production.name
      else
        read_attribute(:name).blank? ? production.name : read_attribute(:name) rescue nil
      end
    end      
  end

  # get the description
	def event_description
    # if the Event has an description
      # return that description
    # else
      # return the Production description
		read_attribute(:description).blank? ? production.description : read_attribute(:description) rescue nil
	end	

  # get the short_description if one exists
  def short_description
    production.short_description rescue nil
  end 

  # get the external_link
  def external_link
    # if the Event has an external_link
      # return that external_link
    # else
      # return the Production external_link
    read_attribute(:external_link).blank? ? production.external_link : read_attribute(:external_link) rescue nil
  end

  # get the ticket_link
  def ticket_link
    # if the Event has an ticket_link
      # return that ticket_link
    # else
      # return the Production ticket_link
    read_attribute(:ticket_link).blank? ? production.ticket_link : read_attribute(:ticket_link) rescue nil
  end

  ##
  ##      Get the venue attributes which are flattened onto the Event couchdb record
  ##

  # get the venue_name
	def venue_name
    # if venue.name is blank return the address split by comma
		venue.name.blank? ? venue.address.split(',').first : venue.name rescue nil
	end

  # get the venue address if one exists
  def venue_address
    venue.address rescue nil
  end

  # get the venue lat if one exists
  def venue_lat
    venue.lat rescue nil
  end

  # get the venue long if one exists
  def venue_long
    venue.long rescue nil
  end

  # get the venue has_location attribute
  def venue_has_location
    venue.has_location rescue nil
  end

  # get the venue use_external_map_link attribute
  def venue_use_external_map_link
    venue.use_external_map_link rescue nil
  end

  # get the venue external_map_link attribute
  def venue_external_map_link
    venue.external_map_link rescue nil
  end

  # get the venue city attribute
  def venue_city
    venue.city rescue nil
  end

  # get the venue name and subtitle for display
  def venue_name_for_css 
    venue.name_and_subtitle.parameterize rescue nil
  end

  # get the venue list order
  def venue_list_order
    venue.list_order rescue nil
  end

  # get the venue include_in_clashfinder attribute
  def venue_include_in_clashfinder
    venue.include_in_clashfinder rescue nil
  end

  # create a string representing the start date of the event using the format 
  # defined in short_time_format
	def date_string_start
		if start_time.is_a? ActiveSupport::TimeWithZone
			start_time.in_time_zone(self.festival.timezone).strftime(self.festival.short_time_format)
		else
			nil
		end
	end

  # create a string representing the end date of the event using the format 
  # defined in short_time_format
  def date_string_end
    if end_time.is_a? ActiveSupport::TimeWithZone
      end_time.in_time_zone(self.festival.timezone).strftime(self.festival.short_time_format)
    else
      nil
    end
  end  

  # create a string representing the start time of the event
  def time_string_start
		if start_time.is_a? ActiveSupport::TimeWithZone
			start_time.in_time_zone(self.festival.timezone).strftime("%H:%M")
		else
			nil
		end
	end

  # create a string representing the end time of the event
  def time_string_end
    if end_time.is_a? ActiveSupport::TimeWithZone
      end_time.in_time_zone(self.festival.timezone).strftime("%H:%M")
    else
      nil
    end
  end  

  # Where no bundle is submitted with the app the first 50 events of the event festival (cronologically)
  # are preloaded.  
  # This method calculates whether a record should be preloaded or not.  
  def preload
    page1_ids = self.festival.events.published.where(event_type: event_type).order("start_time ASC").select(:id).limit(50).collect(&:id)
    should_preload = page1_ids.include?(self.id) ? true : false
  end

  ##     Clashfinder Variables
  # 
  #       For the filters in the what's on listing and the clashfinder in the app (where configured) we provide a shifted date
  #       for events after midnight and before the 'clashfinder_start_hour' (this is configured on the festival model).  
  # 
  #       e.g   Where festival.clashfinder_start_hour is set to '3' an event that starts at 1am on the 3rd of November will be
  #             be rendered in the filters and in the clashfinder view for the 2nd of November.  To enable this the day returned by 
  ##            day_start and filter_day must be shifted back one day.  

  # The function returns the filter_day in the appropriate string format to be used when rendering clashfinder events and for filtering
  # events in the app 
  def filter_day
    day_start.strftime('%m%d')
  end

  # This function returns a DateTime object representing the start of the day in terms of the clashfinder view or filters.  
  def day_start 
    if festival.clashfinder_start_hour == 0
      # if the clashfinder is running from midnight to midnight the day is always correct and doesn't need to be shifted.  
      self.start_time.in_time_zone(self.festival.timezone).change({ hour: festival.clashfinder_start_hour, min: 0, sec: 0 })
    elsif start_time.in_time_zone(self.festival.timezone).hour <= festival.clashfinder_start_hour
      # otherwise shift the day appropriately for late night events.
      self.start_time.in_time_zone(self.festival.timezone).change({ hour: festival.clashfinder_start_hour, min: 0, sec: 0 }) - 1.day
    else
      self.start_time.in_time_zone(self.festival.timezone).change({ hour: festival.clashfinder_start_hour, min: 0, sec: 0 })
    end
  end

  # This function returns the number of minutes between the first hour of this days clashfinder view and the start of the event 
  def start_position
    minutes = (self.start_time.in_time_zone(self.festival.timezone).to_time - self.day_start.to_time) / 1.minutes
  end

  # This function returns the number of minutes between the first hour of this days clashfinder view and the end of the event 
  def end_position
    minutes = (self.end_time.in_time_zone(self.festival.timezone).to_time - self.day_start.to_time) / 1.minutes if self.end_time
  end

  # This function returns the events duration in minutes.  
  def event_duration_in_mins
    minutes = (self.end_time.in_time_zone(self.festival.timezone).to_time - self.start_time.to_time) / 1.minutes if self.end_time
  end

  # This function returns the day of the month the event starts on as a string 
  def start_day
    start_time.in_time_zone(self.festival.timezone).strftime('%-d').to_i
  end

  # This function returns the hour of the day the event starts on as a string
  def start_hour
    start_time.in_time_zone(self.festival.timezone).strftime('%k').to_i
  end

  # This function returns the day of the month the event ends on as a string  
  def end_day
    if end_time 
      end_time.in_time_zone(self.festival.timezone).strftime('%-d').to_i
    end
  end

  # This function returns the hour of the day the event ends on as a string
  def end_hour
    if end_time
      end_time.in_time_zone(self.festival.timezone).strftime('%k').to_i
    end
  end

  # This function returns the minutes of the hour the event ends on as a string
  def end_mins
    if end_time
      end_time.in_time_zone(self.festival.timezone).strftime('%M').to_i
    end
  end
  
  # This function collates the object ready to be sent to couchdb.  
  def to_couch_data
    dn_productions = productions.published.map do |production|
      {
        id: production.id,
        name: production.name, 
        short_description: production.short_description
      }
    end

    data = {
      festival_id: festival.id,
      last_updated_at: DateTime.now,
      name: name,
      short_description: short_description,
      description: event_description,
      image_name: image_thumb,
      image_name_small: image_small_thumb,
      production_id: production_id,
      productions: dn_productions,
      start_time: start_time,
      end_time: end_time,
      filter_day: filter_day,
      date_string_start: date_string_start,
      date_string_end: date_string_end,
      venue: venue_id,
      venue_name: venue_name,
      venue_subtitle: venue.subtitle,
      venue_name_and_subtitle: venue.name_and_subtitle,
      venue_name_for_css: venue_name_for_css,
      venue_address: venue_address,
      venue_lat: venue_lat,
      venue_long: venue_long,
      venue_has_location: venue_has_location,
      venue_use_external_map_link: venue_use_external_map_link,
      venue_external_map_link: venue_external_map_link,
      venue_city: venue_city,
      venue_list_order: venue_list_order,
      venue_include_in_clashfinder: venue_include_in_clashfinder,
      aasm_state: aasm_state,
      event_type: event_type,
      # retaining 'tags' as attribute name for backwards compatibility
      tags: production_tags.map{|t| t.id},
      event_tags: event_tags.map{|t| t.id},
      image_last_updated_at: image_last_updated_at.to_i,
      image_bundled_at: image_bundled_at.to_i,
      external_link: external_link,
      ticket_link: ticket_link,
      private_event: private_event,
      image_loader: image_loader_for_couchdb,
      virtual_event: virtual_event,
      preload: preload,
      # for clashfinder
      start_position: start_position,
      end_position: end_position,
      event_duration_in_mins: event_duration_in_mins,
      start_hour: start_hour, 
      start_day: start_day,
      end_day: end_day,
      end_hour: end_hour,
      end_mins: end_mins
    }

    if is_community_event?
      data[:featured] = featured
    end

    if is_virtual_event? and is_audio_stream?
      data[:audio_stream] = audio_stream
    end

    return data
  end

  def couch_update_or_create is_callback = false
    super

    unless is_callback
      productions.published.each do |production|
        unless production.nil?
          if production.valid_for_app?
            production.couch_update_or_create(true) if production
          end
        end
      end

      unless venue.nil?
        if venue.valid_for_app?
          venue.couch_update_or_create(true) if venue
        end
      end
    end
  end

  ##
  ##      Community Event Notifications 
  ##

  # create a for the creator of a community event to let them know their Event has been published
  # create a push notification for all app users to let them know a new Community Event has been published (currently not used)
  def create_draft_push_notifications_for_creator_and_all_app_users
    if (self.previous_changes.keys & ["aasm_state"]).any? and self.aasm_state === "published"
      if self.event_type === "community_event"
        if self.wallet_address and Address.find_by_address(self.wallet_address)
          puts "\n\n\n\n CREATING NOTIFICATION FOR EVENT #{self.id} TO BE SENT TO #{self.wallet_address} after publishing of Event >>>>>>>>>>>>>>>>>>>>>>>> \n\n\n\n"
          PushNotificationsService.create_draft_model_published_notification_for_address Address.find_by_address(self.wallet_address), self

          # puts "\n\n\n\n CREATING NOTIFICATION FOR EVENT #{self.id} TO BE SENT TO ALL ADDRESSES after publishing of Event >>>>>>>>>>>>>>>>>>>>>>>> \n\n\n\n"
          # PushNotificationsService.create_draft_new_model_available_notification_for_all_app_users self
        end
      end
    end
  end

  # Send a message to the moderators Telegram group to alert them to a new 
  # community event submission.  
  def notify_moderators_about_a_new_submission
    if self.is_community_event?
      unless Token.where(address: self.wallet_address).where(token_type_id: 3).count > 0
        begin
          TelegramService.new(self.festival.organisation).send_message_to_group "There is a submission awaiting moderation.  Moderate now at https://jason.boma.community/#/organisations/#{self.festival.organisation_id}/festivals/#{self.festival.id}/community-events", self.image.url
        rescue Exception => e
          puts "There was an error - #{e}"
        end
      end
    end
  end
end
