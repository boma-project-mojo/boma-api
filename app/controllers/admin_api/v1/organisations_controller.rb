class AdminApi::V1::OrganisationsController < AdminApi::V1::AdminApiController
  
  include ImageUploadConcern

  before_action :set_organisation, only: [:show]

  def show
    render json: @organisation
  end

  def index
    @organisation = policy_scope(Organisation)

    authorize @organisation

    render json: @organisation
  end

  # def create
  #   @festival = Festival.new(festival_params[:attributes])

  #   authorize @festival

  #   if @festival.save
  #     render json: @festival
  #   else
  #     errors = @festival.errors.map do |attribute_name, error|
  #       {
  #         "detail": "#{attribute_name.capitalize} #{error}",
  #         "source": {
  #           "pointer": "data/attributes/#{attribute_name}"
  #         }
  #       }
  #     end
  #     render json: {errors: errors} , status: :unprocessable_entity
  #   end
  # end

  # def update
  #   authorize @festival

  #   if @festival.update(festival_params[:attributes])
  #     render json: @festival
  #   else
  #     errors = @festival.errors.map do |attribute_name, error|
  #       {
  #         "detail": "#{attribute_name.capitalize} #{error}",
  #         "source": {
  #           "pointer": "data/attributes/#{attribute_name}"
  #         }
  #       }
  #     end
  #     render json: {errors: errors} , status: :unprocessable_entity
  #   end
  # end  

  # def destroy
  #   authorize @page    
  #   @page.destroy
  #   render json: {data: {type: 'page', id: params[:id] }}, status: 202
  #   return
  # end

  private
    def set_organisation
      @organisation = Organisation.find(params[:id])
    end

    # def festival_params
    #   params[:data][:attributes][:image] = convert_to_upload params[:data][:attributes][:image_base64]\
    #     unless params[:data][:attributes][:image_base64].empty?

    #   params.require(:data).permit(:id, :attributes => [:id, :name, :start_date, :end_date, :image, :fcm_topic_id, :use_production_name_for_event_name, :timezone, :analysis_enabled, :aasm_state])
    # end


end
