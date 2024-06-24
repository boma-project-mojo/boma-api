class AdminApi::V1::MessagesController < AdminApi::V1::AdminApiController

  before_action :set_festival, only: [:show, :update, :destroy, :index, :create]
  before_action :set_message, only: [:show, :destroy, :update, :send_message]

  def index
    @messages = policy_scope(Message).where(festival_id: @festival.id).page(params[:page]).order('created_at DESC')

    authorize @messages

    meta = {
            "per_page": 25,
            "total_pages": @messages.total_pages,
            "count": @messages.count,
            "total_count": @messages.total_count,
          }

    render json: @messages, include: [], meta: meta

  end

  def show
    render json: @message, include: [:venue, :production, :events, :tags]
  end

  def create
    attrs = message_params[:attributes]
    attrs[:created_by] = current_user.id
    attrs[:festival_id] = @festival.id
    attrs[:topic] = @festival.fcm_topic_id

    if !message_params["attributes"]["address"].nil?
      attrs[:address_id] = Address.where('lower(address) = ?', message_params["attributes"]["address"].downcase).first.id rescue nil
    end

    @message = BomaMessagingService.new_draft(attrs)

    authorize @message

    if @message.save
      render json: @message
    else
      render json: {errors: format_error(@message.errors)} , status: :unprocessable_entity
    end
  end

  def send_message
    authorize @message

    BomaMessagingService.new.send_message(@message)

    render json: {success: true, notice: 'Message sending in progress, this will take several minutes.'}
  end

  def update
    authorize @message

    if @message.update(update_message_params)
      render json: @message
    else
      render json: {errors: format_error(@message.errors)} , status: :unprocessable_entity
    end
  end  

  def destroy
    authorize @message

    if @message.pushed_state == 'draft'
      @message.destroy
      render json: {data: {type: 'message', id: params[:id] }}, status: 202
    else
      errors = [{
        "detail": "Can't delete messages unless they are drafts",
        "source": {
          "pointer": "data/attributes/pushed_state"
        }
      }]
      render json: {errors: errors} , status: :unprocessable_entity
    end

    return
  end

  private

    def set_message
      @message = Message.find(params[:id])
    end

    def set_festival
      @festival = Festival.find(params[:festival_id])
    end

    def message_params
      params.require(:data).permit(:id, :attributes => [:subject,:body,:article_id,:stream,:event_id,:token_type_id,:app_version,:send_at,:address])
    end

    def update_message_params
      params.require(:data).permit(:id, :attributes => [:pushed_state,:send_at])
    end

end