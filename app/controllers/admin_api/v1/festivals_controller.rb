class AdminApi::V1::FestivalsController < AdminApi::V1::AdminApiController
  
  include ImageUploadConcern

  before_action :set_festival, only: [:show, :update]

  def show
    render json: @festival
  end
  

  # It's not possible to send the appropriate HTTP headers with a GET request from javascript so, as a work around we 
  # send a request to generate the file and then return the URL to the file in AWS.  
  # 
  # TODO Make this more secure.  
  def as_pdf
    @festival = Festival.find(params[:festival_id])

    @venues = @festival.venues.where(aasm_state: [:published]).where(venue_type: "performance")

    respond_to do |format|
      format.html { render :template => "accessible_pdf_schedule", :layout => false }
      format.pdf { 
        # pdf = render_to_string pdf: "some_file_name", template: "templates/pdf", encoding: "UTF-8"

        filename = "/data-dumps/#{DateTime.now}-festival-#{params[:festival_id]}-#{SecureRandom.hex}.pdf"

        pdf = render_to_string :template => "accessible_pdf_schedule", pdf: 'filename.pdf', header: { right: '[page] of [topage]' }, formats: [:html]

        resp = UploadService.new.upload_to_s3 "data-dumps/#{filename}", pdf
                
        render json: {
          filename: resp.public_url
        }
      }
    end
  end

  # It's not possible to send the appropriate HTTP headers with a GET request from javascript so, as a work around we 
  # send a request to generate the file and then return the URL to the file in AWS.  
  # 
  # TODO Make this more secure.  
  def as_xml
    respond_to do |format|
      format.xml { 
        resp = DataDumpService.new.to_xml(Festival.find(params[:festival_id]))

        render json: {
          filename: resp.public_url
        }
      }
    end
  end

  # It's not possible to send the appropriate HTTP headers with a GET request from javascript so, as a work around we 
  # send a request to generate the file and then return the URL to the file in AWS.  
  # 
  # TODO Make this more secure.  
  def as_csv
    csv = DataDumpService.new.to_csv(Festival.find(params[:festival_id]))

    respond_to do |format|
      format.csv { 
        filename = "#{DateTime.now}-festival-#{params[:festival_id]}-#{SecureRandom.hex}.csv"

        resp = UploadService.new.upload_to_s3 "data-dumps/#{filename}", csv
                
        render json: {
          filename: resp.public_url
        }
      }
    end
  end

  def index
    @festivals = policy_scope(Festival).where(organisation_id: params[:organisation_id]).order('start_date DESC')

    authorize @festivals

    render json: @festivals
  end

  def create
    attrs = festival_params[:attributes].to_hash

    attrs[:organisation_id] = params[:data][:relationships][:organisation][:data][:id] rescue nil

    @festival = Festival.new(attrs)

    authorize @festival

    if @festival.save
      render json: @festival
    else
      render json: {errors: format_error(@festival.errors)} , status: :unprocessable_entity
    end
  end

  def update
    authorize @festival

    if @festival.update(festival_params[:attributes])
      render json: @festival
    else
      render json: {errors: format_error(@festival.errors)} , status: :unprocessable_entity
    end
  end  

  # def destroy
  #   authorize @page    
  #   @page.destroy
  #   render json: {data: {type: 'page', id: params[:id] }}, status: 202
  #   return
  # end

  private
    def set_festival
      @festival = Festival.find(params[:id])
    end

    def festival_params
      params[:data][:attributes][:image] = convert_to_upload params[:data][:attributes][:image_base64]\
        unless params[:data][:attributes][:image_base64].empty?

      params.require(:data).permit(:id, :attributes => [:id, :name, :start_date, :end_date, :image, :fcm_topic_id, :use_production_name_for_event_name, :timezone, :analysis_enabled, :aasm_state, :list_order, :schedule_modal_type, :bundle_id, :enable_festival_mode_at, :disable_festival_mode_at, :feedback_enabled])
    end
end
