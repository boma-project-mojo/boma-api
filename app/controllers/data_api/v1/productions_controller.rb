class DataApi::V1::ProductionsController < DataApi::V1::DataApiController
  include DataApiConcern

  before_action :set_festival

  # GET /data_api/articles or /data_api/articles.json
  # def index
  #   @articles = AppData::Article.all

  #   render json: @articles
  # end

  # POST /data_api/articles or /data_api/articles.json
  def create
    @production = @festival.productions.where(source_id: production_params[:source_id]).first_or_initialize
    
    authorize(@production, policy_class: DataApi::ProductionPolicy)

    @production.assign_attributes(production_params)
    setup_record_image(@production, production_params[:image])
    @production.tags = production_params[:tag_source_ids].collect {|tsid| @festival.tags.find_by_source_id(tsid)} unless production_params[:tag_source_ids].nil?
    @production.is_checking_app_validity = true
    create_record(@production, production_params[:sandbox])
  end

  # DELETE /data_api/articles/1 or /data_api/articles/1.json
  # def destroy
  #   @data_api_article.destroy
  #   respond_to do |format|
  #     format.html { redirect_to data_api_articles_url, notice: "Article was successfully destroyed." }
  #     format.json { head :no_content }
  #   end
  # end

  private
    def set_festival
      if production_params[:festival_id]
        @festival = Festival.find(production_params[:festival_id])
      else
        render json: {
          response: "You can't create an production without a festival or organisation"
        }, status: :unprocessable_entity
      end
    end

    # Only allow a list of trusted parameters through.
    def production_params
      params.permit([:name, :venue_type, :description, :festival_id, :image, :source_id, :sandbox, :external_link, :tag_source_ids => []])
    end
end
