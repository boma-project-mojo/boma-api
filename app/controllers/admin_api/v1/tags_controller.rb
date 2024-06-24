class AdminApi::V1::TagsController < AdminApi::V1::AdminApiController

  before_action :set_festival_and_organisation, only: [:show, :update, :destroy, :index, :create]
  before_action :set_tag, only: [:show, :update, :destroy]

  def index
    if params[:page]
      if @organisation
        @tags = AppData::Tag.where(organisation_id: @organisation.id).page(params[:page]).order('created_at DESC')
      else
        @tags = AppData::Tag.where(festival_id: @festival.id).page(params[:page]).order('created_at DESC')
      end
    else
      if @organisation
        @tags = AppData::Tag.where(organisation_id: @organisation.id).order('created_at DESC')
      else
        @tags = AppData::Tag.where(festival_id: @festival.id).order('created_at DESC')
      end
    end

    authorize @tags

    unless search_params[:query].nil? or search_params[:query].empty?
      @tags = @tags.where('name ILIKE ?', "%#{search_params[:query]}%")
    end

    if params[:page]
      meta = {
        "per_page": 25,
        "total_pages": @tags.total_pages,
      }
    else
      meta = {}
    end

    render json: @tags, include: [], meta: meta
  end

  def show
    authorize @tag
    render json: @tag
  end

  def create
    @tag = AppData::Tag.new(tag_params)

    @tag.festival_id = @festival.id

    authorize @tag

    if @tag.save
      render json: @tag
    else
      render json: {errors: format_error(@tag.errors)} , status: :unprocessable_entity
    end
  end

  def update
    authorize @tag

    @tag.festival_id = @festival.id

    if @tag.update(tag_params)
      render json: @tag
    else
      render json: {errors: format_error(@tag.errors)} , status: :unprocessable_entity
    end
  end  

  def destroy
    authorize @tag

    @tag.destroy
    render json: {data: {type: 'tag', id: params[:id] }}, status: 202
    return
  end

  private

    def set_tag
      @tag = AppData::Tag.find(params[:id])
    end

    def set_festival_and_organisation
      if params[:festival_id]
        @festival = Festival.find(params[:festival_id])
      end

      if params[:organisation_id]
        @organisation = Organisation.find(params[:organisation_id])
      end
    end

    def tag_params
      params.require(:data).permit(:id, :attributes => [:id, :name, :aasm_state, :tag_type, :description])
    end    

    def search_params
      params.permit(:query)
    end

end