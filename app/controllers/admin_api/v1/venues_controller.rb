class AdminApi::V1::VenuesController < AdminApi::V1::AdminApiController

  include ImageUploadConcern

  before_action :set_festival, only: [:show, :update, :destroy, :index, :create]
  before_action :set_venue, only: [:show, :update, :destroy]
  before_action :venue_tags, only: [:create, :update]


  def show
    authorize @venue
    render json: @venue, include: [:roles, :users]
  end

  def index
    # Bear in mind this action is used for listing venues for select boxes as well as for listing all venues, hence handing pagination with conditionals below

    if params[:page] and params[:per]
      @venues = policy_scope(AppData::Venue).where(festival_id: @festival.id).where(venue_type: venue_type_param).page(params[:page]).per(25).order('created_at DESC')
    else
      @venues = policy_scope(AppData::Venue).where(festival_id: @festival.id).where(venue_type: venue_type_param)
    end

    authorize @venues

    unless search_params[:query].nil? or search_params[:query].empty?
      @venues = @venues.where('name ILIKE ?', "%#{search_params[:query]}%")
    end

    if params[:page] and params[:per]
      meta = {
              "per_page": 25,
              "total_pages": @venues.total_pages,
            }
    end

    render json: @venues, include: [:roles, :users], meta: meta

  end

  def create
    @venue = AppData::Venue.new(venue_params[:attributes])

    @venue.festival_id = @festival.id
    @venue.tags = @venue_tags if @venue_tags
    
    @venue.is_checking_app_validity = true
    
    authorize @venue

    if @venue.save
      render json: @venue
    else
      render json: {errors: format_error(@venue.errors)} , status: :unprocessable_entity
    end
  end

  def update
    authorize @venue

    @venue.festival_id = @festival.id
    @venue.tags = @venue_tags

    if @venue.update(venue_params[:attributes])
      render json: @venue
    else
      render json: {errors: format_error(@venue.errors)} , status: :unprocessable_entity
    end
  end  

  def destroy
    authorize @venue
    if @venue.destroy
      render json: {data: {type: 'venue', id: params[:id] }}, status: 202
    else
      errors = @venue.errors.map do |error|
        {
          "flash": "#{error.message}",
        }
      end
      render json: {errors: errors} , status: :unprocessable_entity      
    end
    
    return
  end

  private

    def set_venue
      @venue = AppData::Venue.find(params[:id])
    end

    def set_festival
      @festival = Festival.find(params[:festival_id])
    end 

    def venue_tags
      @venue_tags = params[:data][:relationships][:tags][:data].map{|t| AppData::Tag.find(t[:id]) }\
        if params[:data][:relationships] and params[:data][:relationships][:tags]
    end

    def venue_params
      params[:data][:attributes][:image] = convert_to_upload params[:data][:attributes][:image_base64]\
        unless params[:data][:attributes][:image_base64].empty?

      params.require(:data).permit(:id, :attributes => [:id, :name, :subtitle, :description, :venue_type, :lat, :long, :image_name, :image, :venue_type, :address_line_1, :address_line_2, :city, :postcode, :external_map_link, :aasm_state, :menu, :list_order, :tags, :include_in_clashfinder, :allow_concurrent_events, :dietary_requirements => [:name, :key]])
    end

    def search_params
      params.permit(:query)
    end

    def venue_type_param
      if params[:venue_type]
        case params[:venue_type].to_sym
        when :performance
          return params[:venue_type] 
        when :retailer
          return params[:venue_type]
        when :community_venue
          return params[:venue_type]
        else
          raise "must be 'performance' or 'retailer'"
        end
      else
        raise "must be 'performance' or 'retailer'"
      end
    end

end