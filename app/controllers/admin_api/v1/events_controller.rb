class AdminApi::V1::EventsController < AdminApi::V1::AdminApiController
  before_action :set_festival, only: [:show, :create, :update, :destroy, :index]
  before_action :set_event, only: [:show, :update, :destroy]

  include ImageUploadConcern

  def index

    # @events = AppData::Event.page(params[:page])
    @events = policy_scope(AppData::Event).where(festival_id: @festival.id).page(params[:page])

    authorize @events

    unless search_params[:event_type].nil? or search_params[:event_type].empty?
      @events = @events.where(event_type: search_params[:event_type])
    end

    unless search_params[:query].nil? or search_params[:query].empty?
      @events = @events.joins(:productions).where('app_data_events.name ILIKE ? OR app_data_productions.name ILIKE ?', "%#{search_params[:query]}%", "%#{search_params[:query]}%")
    end

    unless search_params[:venue_id].nil? or search_params[:venue_id].empty?
      @events = @events.where(venue_id: search_params[:venue_id])
    end    

    if search_params[:order].nil? or search_params[:order].empty? or search_params[:order] != 'diary'
      @events = @events.order('app_data_events.created_at DESC')
    else
      @events = @events.order('venue_id, start_time ASC')
    end

    # unless search_params[:query]
      meta = {
              "per_page": 10,
              "total_pages": @events.total_pages,
              "count": @events.count,
              "total_count": @events.total_count,
            }
    # end

    # render json: @events, include: [:venue, :production, :events, :tags], meta: meta

    unless search_params[:query].nil? or search_params[:query].blank?
      @events.limit(25)
      render json: @events
    else
      render json: @events, include: [:events, :production_tags, :venues], meta: meta
    end

  end  

  def show
    authorize @event
    render json: @event, include: [:venue, :production, :events, :production_tags]
  end

  def create
    attrs = event_params[:attributes].to_hash

    attrs[:venue_id] = params[:data][:relationships][:venue][:data][:id] rescue nil
    attrs[:created_by] = current_user.id
    attrs[:festival_id] = @festival.id
    
    @event = AppData::Event.new(attrs)

    if event_params[:relationships] and event_params[:relationships][:productions]
      event_params[:relationships][:productions][:data].each do |production|
        @event.productions << AppData::Production.find(production[:id])
      end
    end

    authorize @event

    if @event.save
      @event.mirror_production_published_state

      render json: @event, include: :venues
    else
      render json: {errors: format_error(@event.errors)} , status: :unprocessable_entity
    end
  end  

  def update
    if event_params[:attributes]
      attrs = event_params[:attributes].to_hash
    else
      attrs = {}
    end

    attrs[:venue_id] = params[:data][:relationships][:venue][:data][:id] rescue nil
    attrs[:production_id] = params[:data][:relationships][:production][:data][:id] rescue nil
    attrs[:festival_id] = @festival.id

    attrs[:production_ids] = params[:data][:relationships][:productions][:data].map{|p| p[:id] }\
      if params[:data][:relationships] and params[:data][:relationships][:productions]

    authorize @event

    if @event.update(attrs)
      render json: @event, include: :venues
    else
      render json: {errors: format_error(@event.errors)} , status: :unprocessable_entity
    end
  end

  def destroy
    authorize @event
    
    @event.destroy
    render json: {data: {type: 'event', id: params[:id] }}, status: 202
    return
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_event
      @event = AppData::Event.find(params[:id])
    end

    def set_festival
      @festival = Festival.find(params[:festival_id])
    end    

    # # Never trust parameters from the scary internet, only allow the white list through.
    def event_params
      if params[:data][:attributes] and params[:data][:attributes][:image]
        params[:data][:attributes][:image] = convert_to_upload params[:data][:attributes][:image_base64]\
          unless params[:data][:attributes][:image_base64].empty?
      end

      params.require(:data).permit(:id, 
        :attributes => [
          :start_time, :end_time, :aasm_state, :image, :name, :description, :external_link, :audio_stream, :private_event, :featured
        ], 
        :relationships => [
          :productions => [
            :data =>[ 
              :id
            ]
          ]
        ]
      )
    end

    def search_params
      params.permit(:query, :order, :venue_id, :event_type)
    end

end
