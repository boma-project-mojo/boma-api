class AdminApi::V1::SurveysController < AdminApi::V1::AdminApiController
  before_action :set_survey, only: [:show, :update, :destroy]

  def show
    render json: @survey.results
  end

  def create
    @survey = AppData::Survey.new(translate_params_for_nested_attributes survey_params)

    if @survey.save
      render json: @survey
    else
      render json: {errors: format_error(@survey.errors)} , status: :unprocessable_entity
    end
  end

  def update
    if @survey.update translate_params_for_nested_attributes survey_params
      render json: @survey
    else
      render json: {errors: format_error(@survey.errors)} , status: :unprocessable_entity
    end
  end  

  def destroy
    authorize @survey    
    if @survey.destroy
      render json: {data: {type: 'survey', id: params[:id] }}, status: 202
      return
    else
      render json: {errors: format_error(@survey.errors)} , status: :unprocessable_entity
    end
  end

  private

    def set_survey
      @survey = AppData::Survey.find(params[:id])
    end

    def set_festival_and_organisation
      if params[:festival_id]
        @festival = Festival.find(params[:festival_id])
      end

      if params[:organisation_id]
        @organisation = Organisation.find(params[:organisation_id])
      end
    end

    def survey_params
      if params[:data][:attributes][:article_id]
        params[:data][:attributes][:surveyable_id] = params[:data][:attributes][:article_id]
        params[:data][:attributes][:surveyable_type] = "AppData::Article"
      end

      params.require(:data).permit(:id, :organisation_id, attributes: [:article_id, :surveyable_id, :surveyable_type, :enable_at, :disable_at], relationships: [questions: [data: [:id, :question_text, :question_type, answers_attributes: [:id, :answer_text]]]])
    end

    def translate_params_for_nested_attributes permitted_params
      nested_params = {}

      nested_params[:surveyable_id] = permitted_params[:attributes][:article_id] if permitted_params[:attributes] and permitted_params[:attributes][:article_id]
      nested_params[:surveyable_type] = "AppData::Article"
      nested_params[:enable_at] = permitted_params[:attributes][:enable_at]
      nested_params[:disable_at] = permitted_params[:attributes][:disable_at]
      nested_params[:questions_attributes] = permitted_params[:relationships][:questions][:data] if permitted_params[:relationships] and permitted_params[:relationships][:questions]
      
      return nested_params
    end
end