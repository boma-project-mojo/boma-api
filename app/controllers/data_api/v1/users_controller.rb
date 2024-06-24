class DataApi::V1::UsersController < ApplicationController
	skip_before_action :authenticate_user!, :only => [:authenticate]
  skip_before_action :verify_authenticity_token

  def authenticate
    unless params[:email] and params[:password]
      return invalid_login
    else
      resource = User.find_for_database_authentication(:email=>params[:email])
      return invalid_login unless resource
      if resource.valid_for_authentication?{resource.valid_password?(params[:password])}
        sign_in("user", resource)
        render :json => {
          :success=>true, 
          :user_token=>resource.authentication_token, 
          :user_email=>resource.email
        }
        return
      end
      invalid_login
    end
  end

  protected
    def invalid_login
      warden.custom_failure!
      render :json=> {:success=>false, :message=>"Error with your login or password"}, :status=>401
    end
end