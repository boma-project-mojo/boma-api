class AppData::Venue < AppData::Base

  belongs_to :festival
  
  validate :description_is_html, if: -> {is_checking_app_validity and !is_community_venue?}
  validates :description, presence: {message: "can't be blank"}, if: -> {!is_community_venue?}
  validates :name, :presence => {message: "can't be blank"}, unless: -> {is_community_venue?}
  validate :venue_type_is_valid
  validates :external_map_link, link: true, allow_blank: true
  validate :has_image, if: :require_venue_images?
  validates :list_order, :presence => {message: "can't be blank"}, unless: -> {is_community_venue?}

  def require_venue_images?
    if(is_community_venue?)
      false
    elsif self.is_checking_app_validity and self.festival.require_venue_images
      true
    else
      false
    end 
  end

  def venue_type_is_valid
    unless venue_type == "retailer" or venue_type == "performance" or venue_type == "community_venue"
      errors.add(:venue_type, "must be 'retailer', 'performance' or 'community_venue")
    end
  end

  def is_community_venue?
    venue_type == 'community_venue'
  end

  include AASM

  aasm do
    state :draft
    
    state :published, :initial => true

    event :publish do
      transitions :from => [:draft], :to => :published
    end

    event :unpublish do
      transitions :from => [:published], :to => :draft
    end   
  end
  
	acts_as_paranoid

  after_commit :couch_update_or_create, on: [:create, :update, :destroy]

 	has_many :events

  has_many :taggings, :foreign_key => 'taggable_id'
  has_many :tags, -> { where(tag_type: ['retailer', 'performance_venue', 'community_venue']) }, through: :taggings, autosave: false

  scope :community_venues, -> { where(venue_type: :community_venue) }

  def users
    User.joins(:roles).where(roles: { resource_type: 'AppData::Venue', resource_id: self.id })
  end

  def has_image
    unless image.is_a? String    
      if image.url.nil? and image.file.nil?
        errors.add(:image, "must be added")
      end
    end
  end

  resourcify

	include Validations

	mount_uploader :image, ImageUploader

  before_destroy :check_venue_has_no_events

  def check_venue_has_no_events
    return true if self.events.count === 0
    errors.add(:base, "Sorry, you cannot delete venues if they have any associated events, you must first delete all this venue's events.")
    false
    throw(:abort)
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

	def description_is_html
    if is_blank_or_empty_html(description)
      errors.add(:description, "can't be blank")
    end
  end

  def full_address 
    if !osm_id.blank?
      address_str = ""
      address_str += "#{name}, " unless name.blank?
      address_str += "#{address_line_1}, " unless address_line_1.blank?
      address_str += "#{address_line_2}, " unless address_line_2.blank?
      address_str += "#{city}, " unless city.blank?
      address_str += "#{postcode}" unless postcode.blank?
    else
      address_str = "#{name}, #{address}"
    end

    return address_str rescue nil
  end

  # To enable venues to have sub areas without creating recursive relationships where venues can belong to venues
  # I have implemented a sub_title.  The method concatenates the name and subtitle for use in filters in the client and admin section
  # and is also used when generating the venue_name_for_css which is used to apply a colour way to each venue.  
  def name_and_subtitle
    if subtitle
      full_venue_name = "#{name} #{subtitle}" 
    else
      full_venue_name = name
    end
  end

	def to_couch_data

		data = {
			name: name,
      subtitle: subtitle,
      name_and_subtitle: name_and_subtitle,
			lat: lat,
			long: long,
			image_name: image_thumb,
			image_name_small: image_small_thumb,
			venue_type: venue_type,
			description: description,
			has_events: has_events,
			has_location: has_location,
      use_external_map_link: use_external_map_link,
      external_map_link: external_map_link,
      image_bundled_at: image_bundled_at,
      image_last_updated_at: image_last_updated_at,
      image_loader: image_loader_for_couchdb,
      menu: menu,
      dietary_requirements: dietary_requirements,
      list_order: list_order,
      tags: tags.map{|t| t.id}, # need to create habtm mapping
      address: full_address,
      festival_id: festival.id,
      aasm_state: aasm_state,
      include_in_clashfinder: include_in_clashfinder
		}
	end

 	def has_events
 		!events.empty?
 	end

  def total_events
    events.count
  end

  def total_productions
    AppData::Production.joins(:events).where("app_data_events.venue_id = #{id}").count
  end

 	def has_location
 		!lat.nil? and !long.nil?
 	end

  def use_external_map_link
    !external_map_link.nil?
  end

  def couch_update_or_create is_callback = false
    super

    unless is_callback 
      # Only update events if attributes flattened onto the event couchdb record are updated.
      if (self.previous_changes.keys & ["name", "lat", "long", "address"]).any?
        events.select{|ev| ev.valid_for_app? }.each do |e|
    			e.couch_update_or_create(true)
    		end
      end
    end
	end
end
