class AdminApi::V1::AuthController < AdminApi::V1::AdminApiController
  skip_before_action :authenticate_user!, :only => [:session_sign_in, :forgotten_password, :reset_password, :claim_invite]

  def session_sign_in
    unless params[:user] and params[:user][:user_email] and params[:user][:password]
      return invalid_login_attempt
    else
      resource = User.find_for_database_authentication(:email=>params[:user][:user_email])
      return invalid_login_attempt unless resource
      if resource.valid_for_authentication?{resource.valid_password?(params[:user][:password])}
        sign_in("user", resource)
        render :json => {
          :success=>true, 
          :user_token=>resource.authentication_token, 
          :user_email=>resource.email, 
          :user_id=>resource.id,
          :user_data=>ActiveModelSerializers::SerializableResource.new(resource, {namespace: "AdminApi::V1", include: [:roles]}).serializable_hash
        }
        return
      end
      invalid_login_attempt
    end
  end

  def forgotten_password
    unless forgotten_password_params[:email].nil?
      user = User.find_by_email(forgotten_password_params[:email].downcase)
    else
      user = false
    end
    if(user)
      user.send_reset_password_instructions
      render :json => {:success => true, :messages => ["Your reset password email has been sent."]}
    else
      render :json => {:success => false, :errors => ["Sorry, there's no account associated with this email address."]}
    end
  end

  def reset_password
    @user = User.reset_password_by_token({:reset_password_token => reset_password_params[:token] ,:password => reset_password_params[:password],:password_confirmation => reset_password_params[:validatePassword]})
    if @user.errors.count == 0
      render :json => {:success => true, :messages => ["Your password has been reset."], :email => @user.email}
    else
      render :json => {:success => false, :errors => @user.errors.full_messages}
    end
  end

  def claim_invite
    @user = User.reset_password_by_token({:reset_password_token => reset_password_params[:token] ,:password => reset_password_params[:password],:password_confirmation => reset_password_params[:validatePassword]})
    if @user.errors.count == 0
      @user.active!
      render :json => {:success => true, :messages => ["Your invite has been claimed."], :email => @user.email}
    else
      render :json => {:success => false, :errors => @user.errors.full_messages}
    end
  end

  def invalid_login_attempt
    warden.custom_failure!
    render :json=> {:success=>false, :errors=>["Error with your login or password"]}, :status=>401
  end

  private

    def forgotten_password_params
      params.require(:user).permit(:email)
    end

    def reset_password_params
      params.require(:user).permit(:token, :password, :validatePassword)
    end

end