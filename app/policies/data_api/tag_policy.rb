class DataApi::TagPolicy < AppData::TagPolicy
  # users with api_write role for Festival or Organisation can create 
  def create?
    if @tag.organisation_id
      @organisation = Organisation.find(@tag.organisation_id)
      current_user.has_role?('api_write', @organisation)
    elsif @tag.festival_id
      @festival = Festival.find(@tag.festival_id)
      current_user.has_role?('api_write', @festival.organisation)
    end
  end
end