class DataApi::EventPolicy < AppData::EventPolicy
  # users with api_write role for Festival can create  
  def create?
    @festival = Festival.find(@event.festival_id)
    @current_user.has_role?('api_write', @festival)
  end
end