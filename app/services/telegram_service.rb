require 'telegram/bot'

class TelegramService
  # Initialise the Telegram service using the appropriate TELEGRAM_CHAT_ID_ for the supplied organisation
  # Params:
  # +organisation+:: An ActiveRecord Organisation object 
  def initialize(organisation)
  	@token = ENV['TELEGRAM_BOT_TOKEN']
    # there should be one TELEGRAM_CHAT_ID_ set in the dotenv for each organisation in the format TELEGRAM_CHAT_ID_#{org_name_parameterized} e.g TELEGRAM_CHAT_ID_KAMBE_EVENTS
    org_name_parameterized = organisation.name.parameterize(separator: "_").upcase
    @chat_id = ENV["TELEGRAM_CHAT_ID_#{org_name_parameterized}"] ? ENV["TELEGRAM_CHAT_ID_#{org_name_parameterized}"] : ENV['TELEGRAM_CHAT_ID']
  end

  # Send a message to the Telegram group.  
  # Optionally, include a photograph.  
  # Params:
  # +message+:: A string of text (can include HTML) to be included in the message.  
  # +photo+:: The URL to a photograph to include in the message.  
  def send_message_to_group message, photo=nil
  	begin
      Telegram::Bot::Client.run(@token) do |bot|
    		if photo
  		  	bot.api.send_photo(chat_id: @chat_id, photo: photo, caption: message)
  		  else
          bot.api.send_message(chat_id: @chat_id, text: message, parse_mode: 'html')
        end
  		end
    rescue Exception => e
      puts "Unable to send Telegram Message #{e}"
    end
  end

end