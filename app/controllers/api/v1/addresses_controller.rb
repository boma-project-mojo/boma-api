class Api::V1::AddressesController < ApplicationController
  skip_before_action :verify_authenticity_token, :authenticate_user!

  def create_or_update_address
    @address = BomaTokenService.new.create_or_update_wallet(address_params)

    if @address
      render json: {success: true}
    else
      render json: {success: false}
    end
  end

  private
    # # Never trust parameters from the scary internet, only allow the white list through.
    def address_params
      # Reset push notifications badge to zero (assume user has seen notifications if they are opening the app)
      
      params[:settings] = JSON.parse params[:settings] if params[:settings]
      params[:device_details] = JSON.parse params[:device_details] if params[:device_details]
      params[:unread_push_notifications] = 0
      params.permit(:address, :fcm_token, :unread_push_notifications, :app_version, :organisation_id, :registration_type, :registration_id, :settings => {}, :device_details => {})
    end

    def address_preference_params
      @address = Address.find_or_create_by(address: params[:wallet_address])
      params[:address_id] = @address.id
      params.permit(:address_id, :preferable_id, :preferable_type)
    end
end