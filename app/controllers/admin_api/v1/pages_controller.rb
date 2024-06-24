class AdminApi::V1::PagesController < AdminApi::V1::AdminApiController

  include ImageUploadConcern

  before_action :set_festival, only: [:update, :destroy, :index, :create]
  before_action :set_page, only: [:update, :destroy]

  def index
    @pages = policy_scope(AppData::Page).where(festival_id: @festival.id).page(params[:page]).order('created_at DESC')

    authorize @pages

    unless search_params[:query].nil? or search_params[:query].empty?
      @pages = @pages.where('name ILIKE ?', "%#{search_params[:query]}%")
    end

    meta = {
            "per_page": 25,
            "total_pages": @pages.total_pages,
          }

    render json: @pages, include: [:events, :pages, :venues], meta: meta

  end

  def create
    @page = AppData::Page.new(page_params[:attributes])

    @page.festival_id = @festival.id

    authorize @page

    if @page.save
      render json: @page
    else
      render json: {errors: format_error(@page.errors)} , status: :unprocessable_entity
    end
  end

  def update
    authorize @page

    @page.festival_id = @festival.id

    if @page.update(page_params[:attributes])
      render json: @page
    else
      render json: {errors: format_error(@page.errors)} , status: :unprocessable_entity
    end
  end  

  def destroy
    authorize @page    
    @page.destroy
    render json: {data: {type: 'page', id: params[:id] }}, status: 202
    return
  end

  private

    def set_page
      @page = AppData::Page.find(params[:id])
    end

    def set_festival
      @festival = Festival.find(params[:festival_id])
    end

    def page_params
      params[:data][:attributes][:image] = convert_to_upload params[:data][:attributes][:image_base64]\
        unless params[:data][:attributes][:image_base64].empty?

      params.require(:data).permit(:id, :attributes => [:id, :name, :content, :image_name, :image, :aasm_state])
    end

    def search_params
      params.permit(:query)
    end

end