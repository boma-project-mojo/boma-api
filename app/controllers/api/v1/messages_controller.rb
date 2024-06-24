class Api::V1::MessagesController < ApplicationController
  skip_before_action :authenticate_user!, :only => [:index]

	def index
    render json: BomaMessagingService::get_json
		# render json: Net::HTTP.get(URI(ENV['cloudfront_messages_url']))
	end
end
