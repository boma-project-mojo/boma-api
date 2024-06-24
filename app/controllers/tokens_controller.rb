class TokensController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!, :only => [:claim_token]

  before_action :set_token, only: [:claim_token]

  layout 'visitors'

  def claim_token

  end

  private
    def set_token
      @token = Token.find_by_token_hash(params[:token])
   end
end
