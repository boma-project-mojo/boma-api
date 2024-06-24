class AppData::ProductionSerializer < ActiveModel::Serializer
  attributes :id, :name, :short_description, :description, :external_link, :video_link, :ticket_link, :image_thumb, :truncated_description, :truncated_short_description, :aasm_state, :can_update, :image_medium
  type :production
  has_many :events#, serializer: AppData::ChildEventSerializer
  has_many :tags
  # has_many :venues

  def truncated_description
    unless object.description.nil?
      text_only = Nokogiri::HTML(object.description).text
      text_only.truncate(180)
    else
      ""
    end
  end

  def truncated_short_description 
    unless object.short_description.nil?
      object.short_description.truncate(80)
    else
      ""
    end
  end

  # def image_medium_height 
  #   object.image.medium.height
  # end

  # def is_owner
  #   object.owned_by? current_user
  # end

  def can_update
    AppData::ProductionPolicy.new(current_user, object).update?
  end
end
