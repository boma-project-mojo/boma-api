class Api::V1::SurveysController < ApplicationController
  skip_before_action :verify_authenticity_token, :authenticate_user!

  before_action :set_address, only: [:create]

  # To enable all a survey's questions to be answered in one query we have implemented
  # the following.  
  def create
    errors = {
      base: [],
      questions: []
    }
    address_answers = []

    # For each of the questions, check the address answer record will be invalid.  
    if survey_params[:questions]
      survey_params[:questions].each_value do |question|
        @address_answer = AppData::AddressAnswer.new address: @address, question_id: question[:id], answer_id: question[:answer_id]
        
        # Where the records aren't valid, add the validation errors to the error array
        unless @address_answer.valid?
          errors[:questions] << {id: question[:id], errors: @address_answer.errors.full_messages} 
        else
          # Otherwise add the valid records to the address_answers array   
          address_answers << @address_answer
        end
      end

      # If there are no errors, save each of the records and return a success.  
      if errors[:questions].count === 0
        if address_answers.each(&:save)
          render json: {success: true}
        else
          errors[:base] = {errors: ['Sorry, there was an error, please try again.']}
          # It should only get here if there is a 500
          render json: {success: false, errors: errors}, status: :unprocessable_entity
        end
      else
        # Otherwise, return a 422 and send error messages.  
        render json: {success: false, errors: errors}, status: :unprocessable_entity
      end

    else
      # Sent a response with no answers...
      render json: {success: false, errors: ['Sorry, there was an error, please try again.']}, status: :unprocessable_entity
    end
  end

  private

    def set_address
      @address = BomaTokenService.new.create_or_find_address(params[:address])
    end

    def survey_params
      params.permit(:address, questions: [:id, :answer_id])
    end
end