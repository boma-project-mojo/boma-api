class DataApi::V1::EventsController < DataApi::V1::DataApiController
  include DataApiConcern

  before_action :set_festival

  # GET /data_api/articles or /data_api/articles.json
  # def index
  #   @articles = AppData::Article.all

  #   render json: @articles
  # end

  # POST /data_api/articles or /data_api/articles.json
  def create
    @event = @festival.events.where(source_id: event_params[:source_id]).first_or_initialize
    
    authorize(@event, policy_class: DataApi::EventPolicy)

    @event.assign_attributes(event_params)
    @event.is_checking_app_validity = true
    
    @event.venue = @festival.venues.find_by_source_id(event_params[:venue_source_id])

    @event.productions = event_params[:production_source_ids].collect {|psid| @festival.productions.find_by_source_id(psid)} unless event_params[:production_source_ids].nil?

    create_record(@event, event_params[:sandbox])    
  end

  private
    def set_festival
      if event_params[:festival_id]
        @festival = Festival.find(event_params[:festival_id])
      else
        render json: {
          response: "You can't create an event without a festival"
        }, status: :unprocessable_entity
      end
    end

    # Only allow a list of trusted parameters through.
    def event_params
      params.permit([:start_time, :end_time, :name, :festival_id, :venue_source_id, :source_id, :sandbox, :production_source_ids => []])
    end
end
