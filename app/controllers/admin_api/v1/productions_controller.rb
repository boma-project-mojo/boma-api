class AdminApi::V1::ProductionsController < AdminApi::V1::AdminApiController

  include ImageUploadConcern

  before_action :set_festival, only: [:show, :update, :destroy, :index, :create]
  before_action :set_production, only: [:show, :update, :destroy]


  def index
    if params[:page] and params[:per]
      @productions = policy_scope(AppData::Production).where(festival_id: @festival.id).page(params[:page]).order('app_data_productions.created_at DESC')
    else
      @productions = policy_scope(AppData::Production).where(festival_id: @festival.id).order('app_data_productions.created_at DESC')
    end

    authorize @productions

    unless search_params[:query].nil? or search_params[:query].empty?
      @productions = @productions.where('app_data_productions.name ILIKE ?', "%#{search_params[:query]}%")
    end

    unless search_params[:venue_id].nil? or search_params[:venue_id].empty?
      @productions = @productions.joins(:events).where("app_data_events.venue_id = #{search_params[:venue_id]}")
    end

    unless search_params[:tag_id].nil? or search_params[:tag_id].empty?
      @productions = @productions.joins(:tags).where(tags: { id: search_params[:tag_id] })
    end

    if search_params[:acts_without_tags] === "true"
      @productions = @productions.left_outer_joins(:tags).where(tags: { id: nil })
    end

    if search_params[:unpublished_and_unlocked] == "true"
      @productions = @productions.where.not(aasm_state: [:published, :locked])
    end

    if params[:page] and params[:per]
      meta = {
        "per_page": 25,
        "total_pages": @productions.total_pages
      }
    end

    if params[:searching] === "true"
      @productions.limit(25)
      render json: @productions
    else
      render json: @productions, include: [:events, :venues], meta: meta
    end

    # render json: @productions, include: [:events, :tags, :venues], meta: meta
  end

  def show
    authorize @production
    render json: @production, include: [:events]
  end

  def create
    attrs = production_params[:attributes].to_hash
    attrs[:tags] = params[:data][:relationships][:tags][:data].map{|t| AppData::Tag.find(t[:id]) }\
      if params[:data][:relationships] and params[:data][:relationships][:tags]

    attrs[:created_by] = current_user.id

    attrs[:festival_id] = @festival.id

    @production = AppData::Production.new(attrs)

    authorize @production    

    if @production.save
      render json: @production, include: :events
    else
      render json: {errors: format_error(@production.errors)} , status: :unprocessable_entity
    end
  end  


  def update
    authorize @production

    attrs = production_params[:attributes].to_hash
    attrs[:festival_id] = @festival.id

    if params[:data][:relationships] and params[:data][:relationships][:tags]
      attrs[:tags] = params[:data][:relationships][:tags][:data].map{|t| AppData::Tag.find(t[:id]) }
    end

    if @production.update(attrs)
      render json: @production, include: :events
    else
      render json: {errors: format_error(@production.errors)} , status: :unprocessable_entity
    end
  end  

  def destroy
    authorize @production

    @production.destroy
    render json: {data: {type: 'production', id: params[:id] }}, status: 202
    return
  end

  private
    def set_production
      @production = AppData::Production.find(params[:id])
    end

    def set_festival
      @festival = Festival.find(params[:festival_id])
    end    

    def production_params
      # maybe cache this if we ever need to improve performance
      params[:production][:data][:attributes][:image] = convert_to_upload params[:data][:attributes][:image_base64]\
        unless params[:production][:data][:attributes][:image_base64].nil? or params[:production][:data][:attributes][:image_base64].empty?

      params.require(:production).require(:data).permit(:id, :attributes => [:name, :short_description, :description, :external_link, :video_link, :ticket_link, :type, :image, :aasm_state])
    end

    def search_params
      params.permit(:query, :venue_id, :tag_id, :unpublished_and_unlocked, :acts_without_tags)
    end

end
