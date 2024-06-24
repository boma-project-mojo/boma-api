class AdminApi::V1::UsersController < AdminApi::V1::AdminApiController

  before_action :set_festival, only: [:show, :update, :destroy, :index, :send_invite]
  before_action :set_current_festival, only: [:index]
  before_action :set_user, only: [:show, :update, :destroy, :send_invite]

  def show
    authorize @user
    render json: @user, include: ['roles','venues']
  end

  def index
    # Querying when adding or updating a new user
    if find_by_email_params[:checking_user_status] == "true"
      @all_users = User.all
      @users = @all_users.where(email: find_by_email_params[:email].downcase.strip)
    else
      @users = policy_scope(User).page(params[:page]).order('users.created_at DESC')
    
      unless search_params[:query].nil? or search_params[:query].empty?
        @users = @users.where('users.name ILIKE ?', "%#{search_params[:query]}%")
      end

      meta = {
              "per_page": 25,
              "total_pages": @users.total_pages,
            }
    end

    authorize @users

    render json: @users, include: ['roles','venues'], meta: meta

  end

  def create
    attrs = user_params.to_hash

    unless attrs["attributes"]["password"].nil? 
      attrs["attributes"]["password"] = SecureRandom.urlsafe_base64(20, false)\
        if (attrs["attributes"]["password"].empty? | attrs["attributes"]["password"].nil?)
    end
    
    @user = User.new(attrs)

    authorize @user

    if @user.save
      render json: @user, include: ['permissions','venues']
    else
      render json: {errors: format_error(@user.errors)} , status: :unprocessable_entity
    end
  end

  def update

    authorize @user

    attrs = user_params[:attributes].to_hash

    if attrs["password"].blank?
      attrs.delete("password")
    end

    if @user.update(attrs)
      render json: @user, include: ['roles','venues']
    else
      render json: {errors: format_error(@user.errors)} , status: :unprocessable_entity
    end
  end  

  def destroy
    authorize @user    
    @user.destroy
    render json: {data: {type: 'user', id: params[:id] }}, status: 202
    return
  end

  def send_invite
    @user.send_invite @festival
    @user.invite!
    render json: @user, include: ['roles','venues']
  end

  private

    def set_user
      @user = User.find(params[:id])
    end

    def set_festival
      @festival = Festival.find(params[:festival_id])
    end

    def user_params
      params.require(:data).permit(:id, :attributes => [:id, :name, :email, :password])
    end
        
    def search_params
      params.permit(:query)
    end

    def find_by_email_params
      params.permit(:email, :checking_user_status)
    end

    def set_current_festival
      current_user.current_festival = @festival if current_user
    end
end