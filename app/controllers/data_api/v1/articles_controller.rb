class DataApi::V1::ArticlesController < DataApi::V1::DataApiController
  include DataApiConcern
  
  before_action :set_festival
  before_action :set_organisation

  # GET /data_api/articles or /data_api/articles.json
  # def index
  #   @articles = AppData::Article.all

  #   render json: @articles
  # end

  # POST /data_api/articles or /data_api/articles.json
  def create
    if @organisation
      @article = @organisation.articles.where(source_id: article_params[:source_id]).first_or_initialize
    elsif @festival
      @article = @festival.articles.where(source_id: article_params[:source_id]).first_or_initialize
    end

    if @article
      authorize(@article, policy_class: DataApi::ArticlePolicy)

      @article.assign_attributes(article_params)
      @article.remote_image_url = article_params[:image]
      create_record(@article, article_params[:sandbox])  
    else
      render json: {
        response: "You can't create an article without a festival or organisation"
      }, status: :unprocessable_entity
    end
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
    # # Use callbacks to share common setup or constraints between actions.
    # def set_data_api_article
    #   @data_api_article = DataApi::Article.find(params[:id])
    # end

    def set_festival
      if article_params[:festival_id]
        @festival = Festival.find(article_params[:festival_id])
      end
    end

    def set_organisation
      if article_params[:organisation_id]
        @organisation = Organisation.find(article_params[:organisation_id])
      end
    end

    # Only allow a list of trusted parameters through.
    def article_params
      params.permit([:title, :content, :festival_id, :organisation_id, :image, :source_id, :article_type, :sandbox])
    end
end
