class Api::V1::AddressAnswersController < ApplicationController
  skip_before_action :verify_authenticity_token, :authenticate_user!

  before_action :set_address, only: [:create]

  def create
    @address_answer = @address.address_answers.new address_answers_params

    if @address_answer.save
      render json: {success: true}
    else
      render json: {success: false}, status: :unprocessable_entity
    end
  end

  private

    def set_address
      @address = Address.where('lower(address) = ?', params[:address].downcase).first
    end

    def address_answers_params
      params.permit(:question_id, :answer_id)
    end
end