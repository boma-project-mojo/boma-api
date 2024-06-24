class Api::V1::EventsController < ApplicationController
  skip_before_action :verify_authenticity_token, :authenticate_user!

  include ImageUploadConcern

  def create
    @event = AppData::Event.new(event_params)

    @event.event_type = :community_event

    if @event.save
      # Publisher token
      if Token.where(address: event_params[:wallet_address]).where(token_type_id: 3).count > 0
        @event.publish!
      end

      render json: {success: true}
    else
      puts @event.errors
      Rails.logger.info("422 error for event: #{@event.errors}")
      render json: {errors: format_error(@event.errors)}, status: :unprocessable_entity
    end
  end

  private
    # # Never trust parameters from the scary internet, only allow the white list through.
    def event_params
      params[:image] = convert_to_upload({
        data: params[:image_base64],
        name: params[:filename],
        type: params[:filetype]
      }) \
        unless params[:image_base64].empty?

      params[:description] = params[:description].gsub(/(?:\n\r?|\r\n?)/, '<br>')
      
      params.permit(:name, :description, :image, :start_time, :end_time, :festival_id, :venue_id, :wallet_address, :external_link, :virtual_event)
    end
end