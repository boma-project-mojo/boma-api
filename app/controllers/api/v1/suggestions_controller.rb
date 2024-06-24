class Api::V1::SuggestionsController < ApplicationController
  before_action :set_organisation, only: [:create]

  skip_before_action :verify_authenticity_token, :authenticate_user!

  def create
    # Create a suggestion.
    Suggestion.create! suggestion_params

    unless @organisation.nil?
      begin
        message = "<strong>Feedback</strong> \n\n #{suggestion_params[:suggestion]}"

        TelegramService.new(@organisation).send_message_to_group(message)
      rescue Exception => e
        puts "#{e}"
      end

      render json: { response: "thanks!"}
    else
      render json: { response: "Error, sorry try again."}
    end
  end

  private
    def set_organisation
      # Glue code to deal with legacy apps where some sent festival_id in the request payload and
      # some sent just slack_channel
      # 
      # All new app deployments now send organisation_id
      #
      # TODO:  Remove this after ther 2023 Festival Season
      if params[:organisation_id]
        @organisation = Organisation.find(params[:organisation_id])
      elsif params[:festival_id] 
        @organisation = Festival.find(params[:festival_id]).organisation
      elsif params[:slack_channel]
        @organisation = Organisation.find_by_slack_channel_name(params[:slack_channel])
      end
    end

    def suggestion_params
      params.permit(:suggestion, :festival_id)
    end
end