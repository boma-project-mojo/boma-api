class AppData::Article < AppData::Base
	belongs_to :user, optional: true
	belongs_to :organisation, optional: true
	belongs_to :festival, optional: true
	has_one :message
  has_many :surveys, as: :surveyable
	has_many :taggings, :foreign_key => 'taggable_id'
  has_many :tags, -> { where(tag_type: ['article', 'community_article', 'news_tag', 'audio_tag', 'link_tag', 'talks_tag']) }, through: :taggings, autosave: false
  belongs_to :address, optional: true
  has_many :uploads, :as => :uploadable

  scope :boma_articles, -> { where(article_type: :boma_article) }
  scope :community_articles, -> { where(article_type: :community_article) }
  scope :by_article_type, lambda { |article_type|
    where(article_type: article_type)
  }

	mount_uploader :image, ImageUploader

  # Must have festival or organisation relationships
  validates :festival_id, :presence => {message: "can't be blank if organisation_id isn't present"}, unless: :organisation_id
  validates :organisation_id, :presence => {message: "can't be blank if festival_id isn't present"}, unless: :festival_id
	validates :content, presence: true, unless: -> {:is_community_article?}
	validates :title, presence: true, unless: -> {:is_community_article?}
  validates :article_type, presence: true
  validates :external_link, link: true, allow_blank: true
  validates :video_url, link: true, allow_blank: true
  validates :audio_url, link: true, allow_blank: true
  validate :has_image

  acts_as_paranoid

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
  after_commit :create_draft_push_notifications_for_creator_and_all_app_users
  after_create :notify_moderators_about_a_new_submission

  def image_thumb
    unless image.thumb.nil? or image.thumb.url.nil?
      image.thumb.url
    end
  end

  def image_medium
    unless image.medium.nil? or image.medium.url.nil?
      image.medium.url
    end
  end

  def image_small_thumb
    unless image.small_thumb.nil? or image.small_thumb.url.nil?
      image.small_thumb.url
    end
  end

  def is_community_article?
    self.article_type == 'community_article'
  end

  def is_audio_article?
    self.tags.collect(&:id).include?(AppData::Tag.find_by_name("Audio").id) rescue false
  end

  def address_short_hash
  	address.address_short_hash(id) rescue nil
  end

  def organisation_address
    address.organisation_addresses.where(organisation_id: self.festival.organisation_id).first
  end

  # To enable a fast onboarding some records are preloaded.  This method
  # checks whether this record should be included in the preload couchdb view
  # and returns an appropriate boolean.  
  def preload
    if self.festival
      page1_ids = self.festival.articles.published.where(article_type: self.article_type).select(:id).order("created_at DESC").limit(100).collect(&:id)
    else 
      page1_ids = self.organisation.articles.published.where(article_type: self.article_type).select(:id).order("created_at DESC").limit(100).collect(&:id)
    end
    preload = page1_ids.include?(self.id) ? 1 : 0
    return preload
  end

  # return the URL to stream audio content in the app
  # 
  # NB: For Organisations whose data imported using the API (or otherwise) the 
  # audio_url attribute is set with the URL to a pre-processed audio stream hence 
  # the elsif in the following method.  
  def processed_audio_url
    # if audio has been uploaded
      # return the processed URL
    # elsif the audio_url has been set manually
      # return that URL
    # else
      # return nil
    if audio.count > 0
      audio.last.processed_url
    elsif audio_url
      audio_url
    else
      nil
    end
  end

  def processed_video_url
    video.last.processed_url rescue nil
  end

  def audio_state
    audio.last.aasm_state rescue nil
  end

  def video_state
    video.last.aasm_state rescue nil
  end

	def to_couch_data
		data = {
      created_at: created_at,
      festival_id: festival_id,
      preload: preload,
			title: title,
			content: content,
			standfirst: standfirst,
			image_name: image_medium,
			image_name_small: image_thumb,
      aasm_state: aasm_state,
      external_link: external_link,
      tags: tags.map{|t| t.id},
      article_type: article_type,
      audio_url: processed_audio_url,
      video_url: processed_video_url,
      address_short_hash: address_short_hash,
      last_updated_at: created_at,
      image_last_updated_at: image_last_updated_at,
      image_bundled_at: image_bundled_at,
      image_loader: image_loader,
      featured: featured,
      meta: meta,
      surveys: self.surveys.map{|s| s.to_couch_data}
		}

    if is_community_article?
      data[:image_name] = image_medium
    end

    return data
	end

  # To drive engagement to the community noticeboard (People's gallery) this method is called on the 'on_create' callback
  # It creates a push notification for a user to let them know their submission has been accepted and is now published.  
  def create_draft_push_notifications_for_creator_and_all_app_users
     if (self.previous_changes.keys & ["aasm_state"]).any? and self.aasm_state === "published"
      if self.article_type === "community_article"
        if self.address
          puts "\n\n\n\n CREATING NOTIFICATION FOR #{self.id} TO BE SENT TO #{self.address.address} after publishing of Article >>>>>>>>>>>>>>>>>>>>>>>> \n\n\n\n"
          PushNotificationsService.create_draft_model_published_notification_for_address self.address, self
        end
        
        # puts "\n\n\n\n CREATING NOTIFICATION FOR #{self.id} TO BE SENT TO ALL ADDRESSES after publishing of Article >>>>>>>>>>>>>>>>>>>>>>>> \n\n\n\n"
        # PushNotificationsService.create_draft_new_model_available_notification_for_all_app_users self
      end
    end
  end

  # All community article posts (People's Gallery) are currently moderated.  
  # This method sends a Telegram message to the Organisations Moderator channel on Telegram
  # to notify them of a new submission.  
  def notify_moderators_about_a_new_submission
    if self.is_community_article?
      unless Token.where(address: self.wallet_address).where(token_type_id: 3).count > 0
        begin
          TelegramService.new(self.festival.organisation).send_message_to_group "There is a submission awaiting moderation.  Moderate now at https://jason.boma.community/#/organisations/#{self.festival.organisation_id}/articles?article_type=community_article", self.image.url
        rescue Exception => e
          puts "There was an error - #{e}"
        end
      end
    end
  end

end
