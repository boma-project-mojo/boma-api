class AppData::Page < AppData::Base

  belongs_to :festival

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

  # has_paper_trail
	acts_as_paranoid

  after_commit :couch_update_or_create, on: [:create, :update, :destroy]

	mount_uploader :image, ImageUploader

	validates :name, :presence => {message: "can't be blank"}
  validate :has_image
	validate :content_is_html

	include Validations

  # validate the 'content' attribute is HTML
	def content_is_html
    if is_blank_or_empty_html(content)
      errors.add(:content, "can't be blank")
    end
  end  

  # get image thumb URL
  def image_thumb
    unless image.thumb.nil? or image.thumb.url.nil?
      image.thumb.url
    end
  end

  # get image small thumb URL
  def image_small_thumb
    unless image.small_thumb.nil? or image.small_thumb.url.nil?
      image.small_thumb.url
    end
  end

	def to_couch_data

		data = {
			name: name,
			content: content,
			image_name: image_thumb,
			image_name_small: image_small_thumb,
      image_bundled_at: image_bundled_at,
      image_last_updated_at: image_last_updated_at,
      aasm_state: aasm_state,
      order: order,
      image_loader: image_loader_for_couchdb,
      festival_id: self.festival.id
		}

	end

  def couch_update_or_create is_callback = false
    super
  end

end
