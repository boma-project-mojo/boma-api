class AppData::ArticleSerializer < ActiveModel::Serializer
  attributes :id, :title, :standfirst, :external_link, :content, :image_name, :aasm_state, :image_thumb, :image_medium, :audio_url, :video_url, :audio_state, :video_state, :article_type, :creator_has_publisher_token, :address, :publish_at, :created_at
  has_one :message
  has_many :tags
  has_many :surveys

  type :article

  def audio_url
    if object.audio.count > 0
      object.processed_audio_url
    else
      object.audio_url
    end
  end

  def video_url
    if object.video.count > 0
      object.processed_video_url
    else
      object.video_url
    end
  end

  def audio_state
    if object.audio.count > 0
      object.audio_state
    end
  end

  def video_state
    if object.video.count > 0
      object.video_state
    end
  end

  def creator_has_publisher_token
    Address.find_by_address(object.wallet_address).is_publisher? rescue nil
  end

  def address
    object.wallet_address
  end
end