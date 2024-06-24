class AppData::VenueSerializer < ActiveModel::Serializer
  attributes :id, :name, :subtitle, :name_and_subtitle, :lat, :long, :description, :image_name, :image_thumb, :truncated_description, :truncated_menu, :venue_type, :aasm_state, :menu, :dietary_requirements, :total_events, :total_productions, :user_names, :festival_name, :image_medium, :address_line_1, :address_line_2, :city, :postcode, :external_map_link, :list_order, :allow_concurrent_events, :include_in_clashfinder
  type :venue
  has_many :tags
  # has_many :events
  # has_many :roles
  # has_many :users

  def truncated_description
    text_only = Nokogiri::HTML(object.description).text
    text_only.truncate(180)
  end

  def truncated_menu
    text_only = Nokogiri::HTML(object.menu).text
    text_only.truncate(180)
  end  

  def user_names
    object.users.map {|u| "#{u.name} "}
  end

  def festival_name
    object.festival.name unless object.festival_id.blank?
  end

end
