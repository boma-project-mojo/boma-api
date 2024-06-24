class DataApi::V1::VenuesController < DataApi::V1::DataApiController
  include DataApiConcern

  before_action :set_festival

  # before_action :set_data_api_article, only: %i[ show edit update destroy ]

  # GET /data_api/articles or /data_api/articles.json
  # def index
  #   @articles = AppData::Article.all

  #   render json: @articles
  # end

  # POST /data_api/articles or /data_api/articles.json
  def create
    @venue = @festival.venues.where(source_id: venue_params[:source_id]).first_or_initialize

    authorize(@venue, policy_class: DataApi::VenuePolicy)

    @venue.assign_attributes(venue_params)
    @venue.is_checking_app_validity = true
    
    setup_record_image(@venue, venue_params[:image])

    create_record(@venue, venue_params[:sandbox])
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
      if venue_params[:festival_id]
        @festival = Festival.find(venue_params[:festival_id])
      else
        render json: {
          response: "You can't create an venue without a festival"
        }, status: :unprocessable_entity
      end
    end

    # Only allow a list of trusted parameters through.
    def venue_params
      allowed_params = [:name, :venue_type, :description, :festival_id, :source_id, :sandbox, :list_order]
      allowed_params << :image unless params[:image].nil?

      params.permit(allowed_params)
    end
end
