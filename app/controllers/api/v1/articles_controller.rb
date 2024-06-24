class Api::V1::ArticlesController < ApplicationController
  skip_before_action :verify_authenticity_token, :authenticate_user!
  before_action :article_tag, only: [:create]

  include ImageUploadConcern

  def create
    @address = Address.find_by_address(article_params[:wallet_address])

    @article = AppData::Article.new(article_params)
    @article.address = @address

    # Glue code to ensure People's Gallery (Community Article) have an organisation_id even if the app isn't sending it
    @article.organisation_id = Festival.find(article_params[:festival_id]).organisation.id unless @article.organisation_id

    @article.tags << @article_tag

    if @article.save
      # Publisher token
      if Token.where(address: article_params[:wallet_address]).where(token_type_id: 3).count > 0
        @article.publish!
      end

      render json: {success: true}
    else
      render json: {errors: format_error(@article.errors)}, status: :unprocessable_entity
    end
  end

  private
    # # Never trust parameters from the scary internet, only allow the white list through.

    def article_tag
      @article_tag = AppData::Tag.find(params[:tag])
    end

    def article_params
      params[:image] = convert_to_upload({
        data: params[:image_base64],
        name: params[:filename],
        type: params[:filetype]
      }) \
        unless params[:image_base64].empty?
      
      params.permit(:image, :festival_id, :article_type, :wallet_address, :external_link, :content)
    end
end