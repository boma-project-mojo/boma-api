class MessagesController < ApplicationController
  before_action :set_message, only: [:show, :edit, :update, :destroy]
  skip_before_action :authenticate_user!, :only => [:index]

  # GET /messages
  # GET /messages.json
  def index
    @messages = Message.all.order('created_at DESC')

    @message = Message.new
  end
end
