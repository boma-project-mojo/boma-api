class DataApi::V1::TagsController < DataApi::V1::DataApiController
  include DataApiConcern

  before_action :set_festival
  before_action :set_organisation

  # before_action :set_data_api_article, only: %i[ show edit update destroy ]

  # GET /data_api/articles or /data_api/articles.json
  # def index
  #   @articles = AppData::Article.all

  #   render json: @articles
  # end

  # POST /data_api/articles or /data_api/articles.json
  def create
    if @organisation
      @tag = @organisation.tags.where(source_id: tag_params[:source_id]).first_or_initialize
    elsif @festival
      @tag = @festival.tags.where(source_id: tag_params[:source_id]).first_or_initialize
    end

    if @tag
      authorize(@tag, policy_class: DataApi::TagPolicy) 

      @tag.assign_attributes(tag_params)
      create_record(@tag, tag_params[:sandbox])
    else
      render json: {
        response: "You can't create an tag without a festival or organisation"
      }, status: :unprocessable_entity
    end
  end

  private
    def set_festival
      if tag_params[:festival_id]
        @festival = Festival.find(tag_params[:festival_id])
      end
    end

    def set_organisation
      if tag_params[:organisation_id]
        @organisation = Organisation.find(tag_params[:organisation_id])
      end
    end

    # Only allow a list of trusted parameters through.
    def tag_params
      params.permit(:name, :tag_type, :festival_id, :organisation_id, :source_id, :sandbox)
    end
end
