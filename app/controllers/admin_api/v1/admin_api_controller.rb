class AdminApi::V1::AdminApiController < ApplicationController

  skip_before_action :verify_authenticity_token

  after_action :cors_set_access_control_headers

  before_action :authenticate_user_from_token!
  before_action :authenticate_user!

  # before_action :set_paper_trail_whodunnit

  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized
    head :unauthorized
  end

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
end