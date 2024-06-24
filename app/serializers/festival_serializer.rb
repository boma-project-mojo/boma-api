class FestivalSerializer < ActiveModel::Serializer
  attributes :id, :name, :start_date, :end_date, :image_name, :fcm_topic_id, :community_events_enabled, :timezone, :use_production_name_for_event_name, :community_articles_enabled, :analysis_enabled, :aasm_state, :list_order, :schedule_modal_type, :has_articles, :bundle_id, :enable_festival_mode_at, :disable_festival_mode_at, :require_venue_images, :require_production_images, :feedback_enabled
  type :festival
  belongs_to :organisation

  def image_name
    object.image.url
  end

  def has_articles
    object.articles.count > 0
  end
end
