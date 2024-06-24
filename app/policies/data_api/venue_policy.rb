class DataApi::VenuePolicy < AppData::VenuePolicy
  # users with api_write role for Festival can create    
  def create?
    @festival = Festival.find(@venue.festival_id)
    @current_user.has_role?('api_write', @festival)
  end
end