class AdminApi::V1::SetRolesController < AdminApi::V1::AdminApiController

  def venues
    user = User.find(params[:user_id])
    permitted_venue_ids = params[:venue_ids]
    user.roles.where(resource_type:'AppData::Venue').each do |role|
      role.destroy
    end
    unless permitted_venue_ids.nil? or permitted_venue_ids.empty?
      permitted_venue_ids.each do |venue_id|
        user.add_role :editor, AppData::Venue.find(venue_id) 
      end
    end

    if params[:is_festival_admin] === "true" || params[:is_festival_admin] === true
      user.add_role(:admin, Festival.find(params[:festival_id]))
      user.add_role(:admin, Organisation.find(Festival.find(params[:festival_id]).organisation_id))
    end

    render json: {success: true}
  end   

end