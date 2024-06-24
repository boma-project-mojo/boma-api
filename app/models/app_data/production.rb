class AppData::Production < AppData::Base
  include Validations

  attr_accessor :tag_source_ids

  #------------------------------------ VALIDATIONS ------------------------------------#

  # Always validate
  validates :name, :presence => {message: "can't be blank"}
  validates :short_description, :length => {maximum: 500, message: "can't be more than 250 characters"}

  # Validate when publishing
  validate :has_image, if: -> { public_record? and require_production_images? }
  validate :description_not_blank, if: -> { public_record? and require_description? }
  validate :has_valid_events, if: :public_record?
  validates :external_link, link: true, allow_blank: true

  def validate_minimum_image_size
    if image
      image = MiniMagick::Image.open(self.image.path)
      unless image[:width] > 600 && image[:height] > 600
        errors.add :image, "should be at least 600x600px!" 
      end
    end
  end

  # The current validation model allows for productions to be published without any events.  
  # This is to enable festivals to release a lineup of artists without releasing their specific scheduled times.  
  def has_valid_events
    valid_events = events.map{|e| e.valid_for_app? true}

    if valid_events.include? false
      invalid_events_errors = events.select{|e| !e.errors.blank?}
      invalid_events_errors.each do |ie|
        error_message = "#{ie.errors.full_messages.to_sentence} (ID: #{ie.id})"
        errors.add(:events, error_message)
      end
    end
  end   

  #---------------------------------- END VALIDATIONS -----------------------------------#

  # check that the aasm_state is transitioning from :locked to :published
  def publishing?
    aasm_state_was == 'locked' and aasm_state == 'published'
  end

  # if this returns true then the require_production_images attribute is set
  # to true on the related festival model.  
  def require_production_images?
    self.festival.require_production_images
  end

  # if this returns true then the require_description attribute is set
  # to true on the related festival model.   
  def require_description?
    self.festival.require_description
  end

  after_update :mirror_published_state_to_events

  # when creating/updating/publishing/unpublishing a Proudction 
  # also make the same transition on the related Event records.  
  def mirror_published_state_to_events
    if aasm_state == 'published'
      events.where.not(aasm_state: :cancelled).each{|e| 
        unless e.published?
          e.update! aasm_state: :published 
        end
      }
    end
    if aasm_state == 'locked'
      events.where.not(aasm_state: :cancelled).each{|e| 
        unless e.aasm_state == 'locked'
          e.update! aasm_state: :draft
        end
      }
    end
    if aasm_state == 'draft'
      events.where.not(aasm_state: :cancelled).each{|e| 
        unless e.aasm_state == 'draft'
          e.update! aasm_state: :draft
        end
      }
    end
  end

  include AASM

  aasm whiny_persistence: true do
    state :draft, :initial => true
    state :locked
    state :published

    event :lock do
      transitions :from => [:draft], :to => :locked
    end

    event :publish do
      transitions :from => [:locked], :to => :published, after: :set_published_at
    end

    event :unpublish do
      transitions :from => [:published], :to => :locked
    end   

    event :unlock do
      transitions :from => [:locked], :to => :draft
    end

  end

  validate do
    unless attribute_was(:aasm_state) == aasm_state
      case attribute_was :aasm_state
      #from
      when "draft"
        #to
        errors.add(:aasm_state, "cannot transition from #{attribute_was :aasm_state} to #{aasm_state}") unless ["locked"].include?(aasm_state)
      when "locked"
        errors.add(:aasm_state, "cannot transition from #{attribute_was :aasm_state} to #{aasm_state}") unless ["draft","published"].include?(aasm_state)
      when "published"
        errors.add(:aasm_state, "cannot transition from #{attribute_was :aasm_state} to #{aasm_state}") unless ["locked"].include?(aasm_state)
      end
    end
  end

	acts_as_paranoid

  after_commit :couch_update_or_create, on: [:create, :update, :destroy]

  before_create :calculate_preload
  before_update :calculate_preload

	belongs_to :festival
	has_many :event_productions, dependent: :destroy
  has_many :events, through: :event_productions

  belongs_to :owner, :class_name => "User", :foreign_key => "created_by", optional: true

  def owned_by? user
    owner == user
  end

	has_many :venues, through: :events
  has_many :taggings, :foreign_key => 'taggable_id'
  has_many :tags, -> { where(tag_type: 'production') }, through: :taggings, autosave: false

	mount_uploader :image, ImageUploader

  def self.with_published_events
    includes(:events).where(app_data_events: {aasm_state: :published})
  end

  def image_thumb
    unless image.thumb.nil? or image.thumb.url.nil?
      image.thumb.url
    end
  end

  def image_small_thumb
    unless image.small_thumb.nil? or image.small_thumb.url.nil?
      image.small_thumb.url
    end
  end

  # check to see whether related events are being preloaded
  # if so also preload the Production.  
  def calculate_preload 
    if self.events.collect(&:preload).include? true
      self.preload = true
    else
      self.preload = false
    end
  end

	def to_couch_data
		dn_events = events.published_or_cancelled.order('start_time ASC').map do |event|
			{
				id: event.id,
				name: event.name, 
				# Left for backwards compatibility but resolved below to use consistent nomenclature. 
        start_time: event.date_string_start,
        end_time: event.date_string_end,
        # Raw start and end times for displaying full date formats (configurable in the client but also used for community events)
        start_datetime: event.start_time,
        end_datetime: event.end_time,
        # Printed start and end times for displaying short date formats
        date_string_start: event.date_string_start,
        date_string_end: event.date_string_end,
				venue_id: event.venue.id,
				venue_name: event.venue_name,
        venue_subtitle: event.venue.subtitle,
        venue_name_and_subtitle: event.venue.name_and_subtitle,
        venue_has_location: event.venue_has_location,
        image_bundled_at: image_bundled_at.to_i,
        image_last_updated_at: image_last_updated_at.to_i,
        festival_id: self.festival.id,
        aasm_state: event.aasm_state,
        ticket_link: event.ticket_link,
        venue_use_external_map_link: event.venue_use_external_map_link,
        venue_external_map_link: event.venue_external_map_link
			}
		end

		data = {
			name: name,
			description: description,
      short_description: short_description,
      image_name: image_thumb,
      image_name_small: image_small_thumb,
      image_loader: image_loader_for_couchdb,
			events: dn_events,
      image_bundled_at: image_bundled_at.to_i,
      image_last_updated_at: image_last_updated_at.to_i,
      external_link: external_link,
      aasm_state: aasm_state,
      festival_id: self.festival.id,
      preload: preload,
      tags: tags.map{|t| t.id} # need to create habtm mapping
		}
	end

  def couch_update_or_create is_callback = false
    super

    unless is_callback
      events.published_or_cancelled.each do |e|
        if e.valid_for_app?
          e.couch_update_or_create true
        end
      end
    end
  end

end
