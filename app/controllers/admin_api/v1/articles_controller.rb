class AdminApi::V1::ArticlesController < AdminApi::V1::AdminApiController

  include ImageUploadConcern

  before_action :set_festival_and_organisation, only: [:update, :destroy, :index, :create]
  before_action :set_article, only: [:update, :destroy]
  before_action :article_tags, only: [:create, :update]
  
  before_action :presigned_url_params, only: [:request_presigned_url]

  def index
    if @festival and @organisation
      unless params[:article_type].blank?
        # Articles by article_type paginated
        @articles = policy_scope(AppData::Article).where("festival_id = ? OR organisation_id = ? AND article_type = ?", @festival.id, @organisation.id, params[:article_type]).page(params[:page]).order('created_at DESC') 
      else
        unless params[:page].blank?
          # All boma articles paginated
          @articles = policy_scope(AppData::Article).where.not(article_type: :community_article).where("festival_id = ? OR organisation_id = ?", @festival.id, @organisation.id).page(params[:page]).order('created_at DESC')
        else
          # All festival articles not paginated
          @articles = policy_scope(AppData::Article).where("festival_id = ? OR organisation_id = ?", @festival.id, @organisation.id).order('created_at DESC').page(params[:page]).order('created_at DESC') 
        end
      end
    elsif @festival
      unless params[:article_type].blank?
        # Articles by article_type paginated
        @articles = policy_scope(AppData::Article).where(festival_id: @festival.id, article_type: params[:article_type]).page(params[:page]).order('created_at DESC') 
      else
        unless params[:page].blank?
          # All boma articles paginated
          @articles = policy_scope(AppData::Article).where.not(article_type: :community_article).where(festival_id: @festival.id).page(params[:page]).order('created_at DESC')
        else
          # All festival articles not paginated
          @articles = policy_scope(AppData::Article).where(festival_id: @festival.id).order('created_at DESC').page(params[:page]).order('created_at DESC') 
        end
      end
    elsif @organisation
      unless params[:article_type].blank?
        # Articles by article_type paginated
        @articles = policy_scope(AppData::Article).where(organisation_id: @organisation.id, article_type: params[:article_type]).page(params[:page]).order('created_at DESC') 
      else
        unless params[:page].blank?
          # All boma articles paginated
          @articles = policy_scope(AppData::Article).where.not(article_type: :community_article).where(organisation_id: @organisation.id).page(params[:page]).order('created_at DESC')
        else
          # All festival articles not paginated
          @articles = policy_scope(AppData::Article).where(organisation_id: @organisation.id).order('created_at DESC').page(params[:page]).order('created_at DESC') 
        end
      end
    end
    
    authorize @articles

    unless search_params[:query].nil? or search_params[:query].empty?
      @articles = @articles.where('title ILIKE ?', "%#{search_params[:query]}%")
    end

    unless search_params[:aasm_state].nil? or search_params[:aasm_state].empty?
      @articles = @articles.where(aasm_state: search_params[:aasm_state])
    end

    unless search_params[:unpublished_and_unlocked].nil? or search_params[:unpublished_and_unlocked].empty?
      @articles = @articles.where(aasm_state: :published)
    end

    unless params[:page].blank?
      meta = {
        "per_page": 25,
        "total_pages": @articles.total_pages,
      }
    end

    render json: @articles, meta: meta, include: ['surveys', 'surveys.questions', 'surveys.answers']
  end

  def create
    @article = AppData::Article.new(article_params[:attributes])

    if @organisation
      @article.organisation_id = @organisation.id
    end

    if @festival
      @article.festival_id = @festival.id
    end

    @article.user_id = current_user.id
    @article.tags = @article_tags if @article_tags

    authorize @article

    if @article.save
      if @article.audio_url
        AppData::Upload.create! upload_type: "audio", uploadable_type: "AppData::Article", uploadable_id: @article.id, original_url: @article.audio_url
      end

      if @article.video_url
        AppData::Upload.create! upload_type: "video", uploadable_type: "AppData::Article", uploadable_id: @article.id, original_url: @article.video_url
      end

      render json: @article
    else
      render json: {errors: format_error(@article.errors)} , status: :unprocessable_entity
    end
  end

  def update
    authorize @article

    if @organisation
      @article.organisation_id = @organisation.id
    end

    if @festival
      @article.festival_id = @festival.id
    end

    @article.user_id = current_user.id
    @article.tags = @article_tags if @article_tags

    # Checking changed after update returns false even if updated, instead check before updating and create uploads if a new audio/video url is sent
    if article_params[:attributes][:audio_url] != @article.processed_audio_url
      AppData::Upload.create! upload_type: "audio", uploadable_type: "AppData::Article", uploadable_id: @article.id, original_url: article_params[:attributes][:audio_url]
    end

    if article_params[:attributes][:video_url] != @article.processed_video_url
      AppData::Upload.create! upload_type: "video", uploadable_type: "AppData::Article", uploadable_id: @article.id, original_url: article_params[:attributes][:video_url]
    end

    @article.assign_attributes(article_params[:attributes])

    if @article.update(article_params[:attributes])
      render json: @article
    else
      render json: {errors: format_error(@article.errors)}, status: :unprocessable_entity
    end
  end  

  def destroy
    authorize @article    
    @article.destroy
    render json: {data: {type: 'article', id: params[:id] }}, status: 202
    return
  end

  def request_presigned_url
    data = UploadService.new.request_for_presigned_url presigned_url_params[:filename], presigned_url_params[:content_type]
    render json: data
  end

  private

    def set_article
      @article = AppData::Article.find(params[:id])
    end

    def set_festival_and_organisation
      if params[:festival_id]
        @festival = Festival.find(params[:festival_id])
      end

      if params[:organisation_id]
        @organisation = Organisation.find(params[:organisation_id])
      end
    end

    def article_tags
      @article_tags = params[:data][:relationships][:tags][:data].map{|t| AppData::Tag.find(t[:id]) }\
        if params[:data][:relationships] and params[:data][:relationships][:tags]
    end

    def article_params
      params[:data][:attributes][:image] = convert_to_upload params[:data][:attributes][:image_base64]\
        unless params[:data][:attributes][:image_base64].empty?

      # Temporarily removing uploader for audio
      # params[:data][:attributes][:audio] = convert_to_upload params[:data][:attributes][:audio_base64]\
      #   unless params[:data][:attributes][:audio_base64].empty?

      params.require(:data).permit(:id, :attributes => [:id, :title, :standfirst, :content, :image_name, :image, :aasm_state, :tags, :external_link, :video_url, :audio_url, :publish_at, :article_type, :created_at])
    end

    def presigned_url_params
      params.permit(:filename, :content_type)
    end

    def search_params
      params.permit(:query, :aasm_state, :unpublished_and_unlocked)
    end

end