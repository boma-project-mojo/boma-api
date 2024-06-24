# Boma Messaging Service
#
# This service handles:
# 
# 1.  Creating Message objects
# 2.  Sending Messages
# 3.  Creating and caching the messages JSON
# 4.  Sending Scheduled Messages
#
# Messages relate to push notifications.  A Message is created by the user in the CMS in the state draft.  
# Once 'send_message' is called (either by a user action or by a scheduled action to send a notification in future) 
# 1.  A background job is started to create PushNotification records for each qualifying Address*
# 2.  The Message is added to the JSON cache which is hosted on s3 and used to sync the Notifications list 
#     in the client app.  
#
# *See PushNotificationsService for more.  
class BomaMessagingService

  # Initalises a new draft Message object
  # Params:
  # +attrs+:: An object of attributes for this Message
  def self.new_draft attrs
    attrs[:pushed_state] = :draft
    Message.new attrs
  end

  # Change the pushed state for a Message to approved, trigger the background worker to 
  # create notifications for all relevant Addresses and add the message to the JSON cache.   
  # Params:
  # +message+:: The ActiveRecord Message object
  def send_message message
    @festival = Festival.find(message.festival_id)

    # Approve the message, it will be set as :sent by the push_notifications_worker after the push_notifications
    # have been successfully created
    message.update! pushed_state: :approved, sent_at: DateTime.now

    # A bit of a hack to provide the push_notifications_worker with the full set of attributes
    # it requires.  
    message_attributes = message.attributes.merge!(organisation_id: @festival.organisation.id, message_id: message.id)

    begin
      PushNotificationsWorker.perform_async message_attributes
      begin
        # Only cache json that is destined for all app users.  
        if message.token_type_id.nil? and message.app_version.nil? and message.address_id.nil?
          BomaMessagingService::cache_json(@festival)
        end
      rescue Exception => e
        raise "Message id##{message.id} not cached! Please get in touch with admin and reference this message. #{e}"
      end
    rescue Exception => e
      raise "Message id##{message.id} may have failed! Please get in touch with admin and reference this message. #{e}"
    end
  end

  # ---------------------------------------------------- #
  # ----------------- Messages JSON -------------------- #
  # ---------------------------------------------------- #

  # All messages that are public are included in a JSON blob which is hosted on AWS s3.  
  # this JSON is used to sync the content of 'notifications' route in the app with the 
  # notifications that have been sent.  
  #
  # Push notifications should be added to the app's local storage via the data included in 
  # push notifications, sometimes this isn't delivered / handled properly by the app - syncing from this 
  # JSON blob acts as a fail safe and reduces the risk of notifications 'Going missing'.  

  # Get all approved and published Messages for a Festival and construct a JSON object in the format
  # expected for 
  # Params:
  # +message+:: The ActiveRecord Festival object
  def self.get_json festival
    payload = {hash: {}, messages: []}
    Message.approved_or_published.order("created_at DESC")\
      .where(festival_id: festival.id)\
      .where(token_type_id: nil)\
      .where(app_version: nil)\
      .where(address_id: nil).each do |m|

      msg = {
        id: m.id,
        subject: m.subject,
        body: m.body,
        body_with_anchors: m.body_with_anchors,
        sent_at: m.sent_at
      }

      begin
        if m.article_id 
          article = AppData::Article.find(m.article_id)
          msg[:article_id] = m.article_id
          msg[:article_type] = article.article_type
          msg[:name] = article.title
        elsif m.event_id
          event = AppData::Event.find(m.event_id)
          msg[:event_id] = m.event_id
          msg[:event_type] = event.event_type
          msg[:name] = event.name
        end
      rescue ActiveRecord::RecordNotFound => e
        puts "Can't find record #{e}"
      end

      payload[:messages] << msg
    end

    payload[:hash] = Digest::SHA256.base64digest(payload[:messages].to_json).to_s
    return payload.to_json
  end

  # Upload the cached JSON blob for a Festival to s3
  # expected for 
  # Params:
  # +festival+:: The ActiveRecord Festival object
  def self.cache_json festival
    Aws.config.update({
      region: ENV['S3_REGION'],
      credentials: Aws::Credentials.new(ENV['S3_KEY'], ENV['S3_SECRET'])
    })

    s3 = Aws::S3::Client.new
    resp = s3.put_object({
      acl: "public-read",
      cache_control: "max-age=30",
      body: BomaMessagingService::get_json(festival), 
      bucket: ENV['S3_MESSAGES_BUCKET_NAME'], 
      key: "festivals/#{festival.id}/messages.json"
    })

    # Temporary multiply the feed 
    resp = s3.put_object({
      acl: "public-read",
      cache_control: "max-age=30",
      body: BomaMessagingService::get_json(festival), 
      bucket: ENV['S3_MESSAGES_BUCKET_NAME'], 
      key: "festivals/#{festival.id}/#{festival.fcm_topic_id}/messages.json"
    })
  end

  # ---------------------------------------------------- #
  # ---------------- Schedule Messages ----------------- #
  # ---------------------------------------------------- #

  # Send notifications which have been scheduled for a future date/time.  
  # Send messages to the appropriate Telegram thread to alert moderators of notifications
  # that are due to be sent and those that have just been sent.  
  def send_scheduled_messages
    Organisation.all.each do |organisation|
      telegram_message = ""

      now_messages = Message.where(festival_id: organisation.festivals.ids).where(pushed_state: :draft).where('send_at >= ? AND send_at <= ?', DateTime.now.beginning_of_hour, DateTime.now.end_of_hour)

      if(now_messages.count > 0)    
        telegram_message = "<strong>The following scheduled push notifications have just been sent </strong> \n\n"
   
        now_messages.each do |message|
          telegram_message = telegram_message + " - <strong>#{message.subject}</strong> \n    #{message.body} \n\n"
          self.send_message(message)
        end
      end

      next_messages = Message.where(festival_id: organisation.festivals.ids).where(pushed_state: :draft).where('send_at >= ? AND send_at <= ?', DateTime.now.beginning_of_hour + 1.hour, DateTime.now.end_of_hour  + 1.hour)

      if(next_messages.count > 0)
        telegram_message = telegram_message + "<strong>The following scheduled notifications will be sent in 1 hour</strong> \n\n"

        next_messages.each do |message|
          telegram_message = telegram_message + " - <strong>#{message.subject}</strong> \n    #{message.body} \n\n"
        end
      end

      TelegramService.new(organisation).send_message_to_group(telegram_message) if telegram_message != ""
    end
  end

end
