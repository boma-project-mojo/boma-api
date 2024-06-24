class AppData::Base < ActiveRecord::Base
  include Couchdb

  attr_accessor :resize_to_fit, :data_api_request, :sandbox

  validates :source_id, presence: {message: "can't be blank"}, uniqueness: { case_sensitive: false, scope: [:festival_id] }, if: :is_data_api_request?

  # Check if a record is published or destined for publishing
  def public_record?
    if self.class.name === AppData::Event
      is_checking_app_validity or \
      production.publishing? or \
      production.published?
    else
      is_checking_app_validity or \
      publishing? or \
      published?
    end
  end

  # Check if the request comes from the data API
  def is_data_api_request?
    self.data_api_request === true
  end

  self.abstract_class = true

  before_save :update_image_last_updated_at
  # before_save :set_published_at

  before_save :append_target_to_ckeditor_links
  before_validation :append_protocol_to_external_link

  # Where anchor links are included in the HTML copy in an image add `target='_blank'`
  # to ensure links open outside of the app.  
  def append_target_to_ckeditor_links
    begin 
      if self.description
        self.description = self.description.gsub(/<a (?!target)/, '<a target="_blank" ')
      end
    rescue NoMethodError => e
      # puts "No description. Not relevant."
    end

    begin 
      if self.content
        self.content = self.content.gsub(/<a (?!target)/, '<a target="_blank" ')
      end
    rescue NoMethodError => e
      # puts "No description. Not relevant."
    end
  end

  # Add http/https to links submitted to the 'external_link' attribute where required.  
  def append_protocol_to_external_link
    begin 
      unless self.external_link.blank?
        unless self.external_link[/\Ahttp:\/\//] || self.external_link[/\Ahttps:\/\//]
          self.external_link = "http://#{self.external_link}"
        end
        # self.external_link = self.external_link.gsub(/<a /, '<a target="_blank" ')
      end
    rescue NoMethodError => e
      # puts "No description. Not relevant."
    end
  end

  # update the image_last_updated_at attribute if the image has been changed.  
  def update_image_last_updated_at
    if changes.key? :image
      self.image_last_updated_at = DateTime.now
    end
  end

  # uupdate the image_bundled_at attribute with the current datetime.  
  def touch_image_bundled_at!
    begin
      update!(image_bundled_at: DateTime.now)
    rescue Exception => e
      puts "Error with #{self.class.name} #{self.id} #{e.inspect}"
    end
  end

  # take a copy of the image for this model and store it in /images/[festival_id]
  def bundle_image
    begin
      FileUtils.mkdir_p('./images/'+self.festival_id.to_s)
      
      URI.open(Rails.root.join('./images/', self.festival_id.to_s, self.prefix+'-'+id.to_s+'-thumb.jpg'), 'wb') do |file|
        file << URI.open("#{image.thumb.url}").read
      end

      # update!(image_bundled_at: DateTime.now)
    rescue Exception => e
      puts "Error with #{self.class.name} #{self.id} #{e.inspect}"
    end
  end

  # check that an image is included in the bundle
  def image_is_bundled?
    self.image_bundled_at != nil && self.image_last_updated_at < self.image_bundled_at rescue false
  end

  # if an image is not included in the bundle include the loader in the couchdb record
  # this is to manage the size of the data dump which is included in the bundle.  
  def image_loader_for_couchdb
    if image_is_bundled?
      nil
    else
      self.image_loader
    end
  end

  # check a record has aasm_state :published
  def is_published
    if aasm_state != "published"
      errors.add(:aasm_state, "must be published")
    end
  end

  # validate to check that a record has an image 
  def has_image
    if image.url.nil? and image.file.nil?
      errors.add(:image, "must be added")
    end
  end

  # return the url for the image_medium version if present
  def image_medium
    unless image.nil? or image.url.nil?
      image.medium.url
    end    
  end

  # validate that the description isn't blank
  def description_not_blank
    if is_blank_or_empty_html(description)
      errors.add(:description, "can't be blank")
    end
  end

  # get the base64 for the image loader version.  
  def image_loader
    Base64.strict_encode64(image.loader.read) rescue nil
  end

  # set the published at attribute on the model.  
  def set_published_at
    begin
      self.published_at = DateTime.now
    rescue NoMethodError
      #Model doesn't have published_at attribute, skipping.
    end
  end

  # get any related audio uploads for this model
  def audio
    self.uploads.audio
  end

  # get any related video uploads for this model
  def video
    self.uploads.video
  end

  # Fallback for models that don't have this state implemented in aasm_state
  def preview?
    false
  end

  # Fallback for models that don't have this state implemented in aasm_state
  def cancelled?
    false
  end
end