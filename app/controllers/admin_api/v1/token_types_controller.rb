class AdminApi::V1::TokenTypesController < AdminApi::V1::AdminApiController
  def index
  	@token_types = TokenType.where(organisation_id: Festival.find(token_type_params[:festival_id]).organisation_id)
  
    render json: @token_types
  end

  private
  	def token_type_params
      params.permit(:festival_id)
  	end
end