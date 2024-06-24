class Feed::V1::FeedController < ApplicationController
  before_action :set_festival, only: [:feed, :csv_dump, :bash_dump]

  skip_before_action :verify_authenticity_token

  after_action :cors_set_access_control_headers

  # before_filter :authenticate_user_from_token!
  # before_filter :authenticate_user!
  skip_before_action :authenticate_user!, :only => [:feed, :csv_dump, :bash_dump]

  def feed
    render json: JSON::dump(DataFeedService.new(@festival).to_hash)
  end

  def csv_dump
    @data = DataDumpService.new.to_csv(@festival)
    respond_to do |format|
      format.csv { send_data @data, filename: "data-dump-#{Date.today}.csv" }
    end
  end

  def bash_dump
    @data = DataDumpService.new.to_bash(@festival)

    send_data @data, :filename => "image-dump.sh"
  end  

  private

  # For all responses in this controller, return the CORS access control headers. 
  def cors_set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Headers'] = 'X-AUTH-TOKEN, X-API-VERSION, X-Requested-With, Content-Type, Accept, Origin'
    headers['Access-Control-Allow-Methods'] = 'POST, GET, PUT, DELETE, OPTIONS'
    headers['Access-Control-Max-Age'] = "1728000"
  end

  def authenticate_user_from_token!
    authenticate_with_http_token do |user_token, options|
      user_email = options[:user_email].presence
      user       = user_email && User.find_by_email(user_email)
  
      user_token = user_token.split('"')[1]
      if user && Devise.secure_compare(user.authentication_token, user_token)
        sign_in user, store: false
      else
        head :unauthorized
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.

    def set_festival
      @festival = Festival.find(params[:festival_id])
    end    

end