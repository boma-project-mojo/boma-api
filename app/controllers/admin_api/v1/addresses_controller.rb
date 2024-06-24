class AdminApi::V1::AddressesController < AdminApi::V1::AdminApiController
  before_action :set_address

  def show
    render json: @address
  end

  private

    def set_address
      @address = Address.find_by_address(address_params[:id])
    end

    def address_params
      params.permit(:id)
    end
end