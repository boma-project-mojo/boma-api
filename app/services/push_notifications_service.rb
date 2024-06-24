#####

#
# This service manages all aspects of creating, approving and sending push notifications.  
# 
# To allow for easy debugging and tracking of notifications a PushNotification record is created in the database
# for each OrganisationAddress which has opted to recieve notifications for this stream.  
# 
# The notifications are created when the CMS user clicks 'Send' or when a push notification that is scheduled
# to be sent is sent by the `send_scheduled_notifications` rake task.  
#
# They are created by a Sidekiq worker (PushNotificationsWorker) to allow for scale.  
#
# PushNotification state is tracked via aasm_state.  A PushNotification is created in draft state, it's 'approved', 
# once sent it's 'sent' and if an error occured it's  state becomes 'failed' and the push_error attribute is populated.  
#
# Notifications are approved and sent to GoRush and then on to FCM or APNS when the rake take `approve_and_send_push_notifications` is 
# run.  This is completed by a cronjob 
#
# Notifications can be triggered manually for one address using the `approve_all_drafts_for_address_and_send` method of this service.  

require 'fcm'

class PushNotificationsService

  # These are the streams that are available in the boma-admin section when creating messages
  def self.streams
    ['critical-comms','hq-comms','article-audio-notifications','article-news-notifications']
  end

  # ---------------------------------------------------- #
  # ---------------= Useful Functions ------------------ #
  # ---------------------------------------------------- #

  # Batch update the pushed_state attribute
  # batch_of_notifications  Array of PushNotification ActiveRecord objects (array)
  # new_pushed_state        The push state to update all records to (string)
  # error                   Any error that needs to be recorded on the PushNotification record (string)
  def self.update_pushed_state batch_of_notifications, new_pushed_state, error=nil
    batch_to_process = []

    batch_of_notifications.each do |notification|
      notification.pushed_state = new_pushed_state

      if error
        notification.push_error = error
      end

      batch_to_process << notification
    end

    PushNotification.import batch_to_process, {
      raise_error: true,
      on_duplicate_key_update: {
        columns: [:pushed_state],
        timestamps: true
      }
    }
  end

  # Initialise a new draft push notification
  # attrs   An object of the attributes of a PushNotification (object)
  def self.new_draft attrs
    attrs[:pushed_state] = :draft
    PushNotification.new attrs
  end

  # Create a new draft push notification
  # attrs   An object of the attributes of a PushNotification (object)
  def self.create_draft attrs
    attrs[:pushed_state] = :draft
    PushNotification.create! attrs
  end

  # ---------------------------------------------------- #
  # -------------- Create Notifications ---------------- #
  # ---------------------------------------------------- #

  # Create one draft push notification to for an address
  # subject                 The subject of the notification (string)
  # body                    The body of the notification (string)
  # address                 An ActiveRecord Address object (ActiveRecord Object)
  # model                   An ActiveRecord object for the related model Article / Event (ActiveRecord Object)
  # stream                  The stream the notification has been sent in (string)
  # organisation_address    An ActiveRecord OrganisationAddress object (ActiveRecord Object)
  # message_id              An id for the related message model
  def self.create_draft_push_notification_for_address subject, body, address, model, stream, organisation_address, message_id=nil
    # For the purpose of using the appropriate push notification server to send the notifications
    # we store the organisation_id of the related model.  
    #
    # Messages and Events are only linked to the organisation through the festival model
    # Articles can belong to either the Festival or the Organisation.  Hence we favour the festival
    # relationship over the direct relationship to an Organisation.   
    organisation_id = model.festival ? model.festival.organisation_id : model.organisation_id
    festival_id = model.festival.id rescue nil

    pn_attrs = {
      subject: subject,
      body: body,
      address_id: address.id,
      notification_type: 'personalised',
      stream: stream,
      festival_id: festival_id,
      organisation_id: organisation_id,
      unread_push_notifications: organisation_address.unread_push_notifications,
      registration_type: organisation_address.registration_type,
      registration_id: organisation_address.registration_id
    }

    # If this push notification is related to a message model
    if message_id
      pn_attrs[:message_id] = message_id
    end

    # If this push notification has a related article or event model
    if model
      pn_attrs[:messagable_type] = model.class.name.to_s
      pn_attrs[:messagable_id] = model.id
    end

    self.create_draft pn_attrs
  end

  # Create draft notification for all app users (Called from MesssagesController)
  # attrs    An object of attributes required to create the notification.
  def self.create_draft_notification_for_all_organisation_app_users attrs
    raise "must have value 'stream' with value '#{PushNotificationsService::streams.join(',')}" unless\
      attrs.has_key? "stream" and attrs["stream"].class == String and PushNotificationsService::streams.include?(attrs["stream"])

    if attrs["article_id"]
      model = AppData::Article.find(attrs["article_id"])
    elsif attrs["event_id"]
      model = AppData::Event.find(attrs["event_id"])
    elsif attrs["message_id"]
      model = Message.find(attrs["message_id"])
    end

    if attrs['address_id']
      organisation_addresses = OrganisationAddress.where(organisation_id: attrs['organisation_id']).where.not(registration_id: "").where(address_id: attrs['address_id']).where("settings->>? = ?", attrs["stream"], 'true').uniq{|oa|
        unless(oa.registration_id.nil?)
          oa.registration_id
        else
          oa.fcm_token
        end
      }
    elsif attrs['token_type_id'] 
      organisation_addresses = OrganisationAddress.joins(:tokens).where(:tokens => {:token_type_id => attrs['token_type_id'], :aasm_state => :mined}).where(organisation_id: attrs['organisation_id']).where.not(registration_id: "").where("organisation_addresses.settings->>? = ?", attrs["stream"], 'true').uniq{|oa|
        unless(oa.registration_id.nil?)
          oa.registration_id
        else
          oa.fcm_token
        end
      }
    elsif attrs['app_version']
      organisation_addresses = OrganisationAddress.where(organisation_id: attrs['organisation_id']).where.not(registration_id: "").where(app_version: attrs['app_version']).where("settings->>? = ?", attrs["stream"], 'true').uniq{|oa|
        unless(oa.registration_id.nil?)
          oa.registration_id
        else
          oa.fcm_token
        end
      }
    else
      organisation_addresses = OrganisationAddress.where(organisation_id: attrs['organisation_id']).where.not(registration_id: "").where("settings->>? = ?", attrs["stream"], 'true').uniq{|oa|
        unless(oa.registration_id.nil?)
          oa.registration_id
        else
          oa.fcm_token
        end
      }
    end
      
    self.batch_create_draft_push_notification_for_addresses attrs["subject"], attrs["body"], organisation_addresses, model, attrs["stream"], attrs["message_id"]

    if attrs["message_id"]
      Message.find(attrs["message_id"]).update! pushed_state: :sent, sent_at: DateTime.now
    end
  end

  # Create a batch of draft push notifications
  # subject                 The subject of the notification (string)
  # body                    The body of the notification (string)
  # organisation_addresses  An array of ActiveRecord OrganisationAddress objects (array)
  # model                   An ActiveRecord object for the related model Article / Event (ActiveRecord Object)
  # stream                  The stream the notification has been sent in (string)
  # message_id              The id of the related message model
  def self.batch_create_draft_push_notification_for_addresses subject, body, organisation_addresses, model, stream, message_id=nil
    batch_to_process = []

    # For the purpose of using the appropriate push notification server to send the notifications
    # we store the organisation_id of the related model.  
    #
    # Messages and Events are still only linked to the organisation through the festival model
    # Articles can belong to either the Festival or the Organisation.  Hence we favour the festival
    # relationship over the direct relationship to an Organisation.   
    organisation_id = model.festival ? model.festival.organisation_id : model.organisation_id
    festival_id = model.festival.id rescue nil

    pn_attrs = {
      subject: subject,
      body: body,
      notification_type: 'personalised',
      festival_id: festival_id,
      organisation_id: organisation_id,
    }

    # If this push notification is related to a message model
    if message_id
      pn_attrs[:message_id] = message_id
    end

    # If this push notification has a related article or event model
    if model
      pn_attrs[:messagable_type] = model.class.name.to_s
      pn_attrs[:messagable_id] = model.id
    end

    organisation_addresses.each do |oa|
      pn_attrs[:address_id] = oa.address_id
      pn_attrs[:unread_push_notifications] = oa.unread_push_notifications+1

      if oa.registration_id
        pn_attrs[:registration_type] = oa.registration_type
        pn_attrs[:registration_id] = oa.registration_id
      else
        pn_attrs[:registration_type] = 'LEGACY_FCM'
        pn_attrs[:registration_id] = oa.fcm_token
      end

      batch_to_process << self.new_draft(pn_attrs)
    end

    PushNotification.import batch_to_process, {raise_error: true}
  end

  def self.create_draft_model_published_notification_for_address address, model
    settings = address.organisation_address_settings_from_festival_id(model.festival_id)

    if settings and settings['submission-published-notifications']
      if model.class.name.to_s === "AppData::Article"
        subject = "People's Gallery Post Published!"
        body = "Your People's Gallery Post has been published in the Shambala app."
        stream = "app_data_article-published"
      elsif model.class.name.to_s === "AppData::Event"
        subject = "Community Event Published!"
        body = "Your Community Event has been published in the Shambala app."
        stream = "app_data_event-published"
      end

      self.create_draft_push_notification_for_address subject, body, address, model, stream, address.organisation_address_from_festival_id(model.festival_id)
    end
  end

  ## DEPRECATED SINCE STORING PERFERENCES BY ADDRESS
  ## OPENED UP THE POTENTIAL TO PROFILE USERS AND WAS REMOVED.  
  def self.create_draft_model_preference_created_notification_for_address address, model
    if address.settings and address.settings['submission-love-notifications']
      if model.class.name.to_s === "AppData::Article"
        subject = "Your work is appreciated!"
        body = "A Shambalan hearted your People's Gallery post, nice!"
        stream = "app_data_article-hearted"
      elsif model.class.name.to_s === "AppData::Event"
        subject = "A Shambalan scheduled your event!"
        body = "Someone added your Community Event to their schedule."
        stream = "app_data_event-hearted"
      end
      
      self.create_draft_push_notification_for_address subject, body, address, model, stream, address.organisation_address_from_festival_id(model.festival_id)
    end
  end

  # Isn't currently used.
  
  # def self.create_draft_new_model_available_notification_for_all_organiation_app_users model
  #   if model.class.name.to_s === "AppData::Article"
  #     subject = "A new People's Gallery Post has been created!"
  #     body = "Check out your fellow Shambalan's work now in the People's Gallery!"
  #     stream = "app_data_article-new_post"
  #   elsif model.class.name.to_s === "AppData::Event"
  #     subject = "A Shambalan has posted a new event!"
  #     body = "Take a look at the full details now."
  #     stream = "app_data_event-new_post"
  #   end

  #   OrganisationAddress.where(organisation_id: attrs["organisation_id"]).where.not(id: model.address_id).uniq{|oa| oa.fcm_token}.each do |address|
  #     self.create_draft_push_notification_for_address subject, body, address, model, stream
  #   end
  # end

  # ---------------------------------------------------- #
  # --------------- Send Notifications ----------------- #
  # ---------------------------------------------------- #

  # Approve and send all draft push notifications in batches
  #
  # This function is called from the approve_and_send_push_notifications task which is triggered on a cron 
  # every 10 minutes
  # dry_run       shows logs rather than sending request if set to true (boolean)
  # limit         the maximum number of notifications to send with this request (int)
  def self.approve_all_drafts_and_send_in_batches dry_run=false, limit=nil
    # Get all draft notifications grouped by message content and messageable_id,
    # and count of unread push notifications
    all_draft_notifications_grouped = PushNotification.drafts.where(notification_type: 'personalised').limit(limit).group_by{|pn| [pn.messagable_id, pn.body, pn.unread_push_notifications, pn.organisation_id] }

    # Loop through each batch of notifications and approve and send in batches
    all_draft_notifications_grouped.each do |key, batch_of_notifications|
      begin
        self.approve_batch! batch_of_notifications, dry_run
        self.send_batch! batch_of_notifications, dry_run
      rescue Exception => e
        self.update_pushed_state batch_of_notifications, :failed, e
        puts "error sending message --> #{e}"
      end
    end
  end


  # Approve and send all draft push notifications belonging to a certain address
  # address_id    id of Address (int)
  # dry_run       shows logs rather than sending request if set to true (boolean)
  def self.approve_all_drafts_for_address_and_send address_id, dry_run=false
    all_draft_notifications = PushNotification.drafts.where(notification_type: 'personalised').where(address_id: address_id)

    all_draft_notifications.each do |push_notification|
      begin
        self.approve! push_notification, dry_run
        self.send! push_notification, dry_run
      rescue Exception => e
        push_notification.update! pushed_state: :failed, push_error: e
        puts "error sending message --> #{e}"
      end
    end
  end

  # Approve a PushNotification 
  # push_notification   PushNotification ActiveRecord Object (ActiveRecord object)
  def self.approve! push_notification, dry_run=false
    raise "must be of class ActiveRecord::PushNotification" unless\
      push_notification.kind_of? ActiveRecord::Base and push_notification.class.name == "PushNotification"

    raise "must be of push state 'draft'" unless\
      push_notification.pushed_state.to_sym == :draft

    if push_notification.messagable and push_notification.messagable.draft?
      e = "the article or event related to this message is not published yet, publish it before sending this message #{push_notification.messagable.class.name} - #{push_notification.messagable.id}" 
      push_notification.update! pushed_state: :failed, push_error: e
      raise e
    end

    unless dry_run
      push_notification.approve! 
    else
      puts "DRY RUN - push_notification.update! pushed_state: :approved"
    end 
  end

  # Approve a batch of notifications
  # batch_of_notification   An array of ActiveRecord::PushNotification objects (ActiveRecord::PushNotification)
  def self.approve_batch! batch_of_notifications, dry_run
    batch_to_process = []

    raise "must be of class ActiveRecord::PushNotification" unless\
      batch_of_notifications.collect {|pn| pn.kind_of? ActiveRecord::Base and pn.class.name == "PushNotification"}.uniq === [true]

    raise "must be of push state 'draft'" unless\
      batch_of_notifications.collect{|pn| pn.pushed_state}.uniq === ["draft"]

    raise "all notifications must have the same organisation_id" unless\
      batch_of_notifications.collect {|pn| "#{pn.organisation_id}"}.uniq.count === 1

    unless dry_run
      self.update_pushed_state batch_of_notifications, :approved
    else
      puts "DRY RUN - push_notification.update! pushed_state: :approved"
    end 
  end

  # Send a PushNotification 
  # push_notification   PushNotification ActiveRecord Object (ActiveRecord object)
  def self.send! push_notification, dry_run=false
    raise "must be of class ActiveRecord::PushNotification" unless\
      push_notification.kind_of? ActiveRecord::Base and push_notification.class.name == "PushNotification"

    raise "must be of push state 'approved'" unless\
      push_notification.pushed_state.to_sym == :approved or dry_run === true

    if push_notification.notification_type === "personalised"
      if push_notification.registration_type === "APNS"
        # Apple
        puts "SENDING WITH APNS"
        make_apns_request(push_notification, dry_run)
      elsif push_notification.registration_type === "FCM"
        # Android
        puts "SENDING WITH FCM FOR ANDROID"
        make_fcm_request(push_notification, dry_run)
      elsif push_notification.registration_type === nil and push_notification.fcm_token != nil
        # Legacy using FCM
        puts "SENDING USING LEGACY SYSTEM"
        make_personalised_fcm_request(push_notification, dry_run)
      else
        raise "Error, check the Address for this PushNotification has an associated OrganisationAddress. "
      end
    end
  end

  # Send a batch of notifications
  # batch_of_notification   An array of ActiveRecord::PushNotification objects (ActiveRecord::PushNotification)
  # dry_run                 Set to true to test without sending the request to GoRush
  def self.send_batch! batch_of_notifications, dry_run=false
    batch_to_process = []

    raise "must be of class ActiveRecord::PushNotification" unless\
      batch_of_notifications.collect {|pn| pn.kind_of? ActiveRecord::Base and pn.class.name == "PushNotification"}.uniq === [true]

    raise "must be of push state 'approved'" unless\
      batch_of_notifications.collect{|pn| pn.pushed_state}.uniq === ["approved"]

    raise "all notifications must have the same subject" unless\
      batch_of_notifications.collect{|pn| pn.subject}.uniq.count === 1

    raise "all notifications must have the same body" unless\
      batch_of_notifications.collect {|pn| pn.body}.uniq.count === 1

    raise "all notifications must have the same unread_push_notifications" unless\
      batch_of_notifications.collect {|pn| pn.unread_push_notifications}.uniq.count === 1

    raise "all notifications must have the same messagable_id and messagable_type" unless\
      batch_of_notifications.collect {|pn| "#{pn.messagable_id}-#{pn.messagable_type}"}.uniq.count === 1

    raise "all notifications must have the same organisation_id" unless\
      batch_of_notifications.collect {|pn| "#{pn.organisation_id}"}.uniq.count === 1

    grouped_by_pn_provider = batch_of_notifications.group_by{|pn| pn.registration_type.to_s }

    # FCM has a maximum batch size of 1000, and for FCM send in similar batch sizes otherwise sending all 
    # the messages in one batch is just pure lunacy with larger festivals.  

    # APNS
    if grouped_by_pn_provider['APNS']
      grouped_by_pn_provider['APNS'].in_groups_of(900, false).each do |small_batch|
        puts "SENDING #{small_batch.count} MESSAGESS WITH APNS"
        make_batch_apns_request(small_batch, dry_run)
      end
    end

    # FCM
    if grouped_by_pn_provider['FCM']  
      grouped_by_pn_provider['FCM'].in_groups_of(900, false).each do |small_batch|
        puts "SENDING #{small_batch.count} MESSAGESS WITH FCM FOR ANDROID"
        make_batch_fcm_request(small_batch, dry_run)
      end
    end

    if grouped_by_pn_provider['LEGACY_FCM']
      grouped_by_pn_provider['LEGACY_FCM'].each do |pn|
        self.make_personalised_fcm_request(pn)
      end
    end
  end

  # Make an a request ot the GoRush server to send one apns notification
  # push_notification   PushNotification ActiveRecord Object (ActiveRecord object)
  # dry_run             Set to true to test without sending the request to GoRush
  def self.make_apns_request push_notification, dry_run=false
    raise "must have value 'subject' with value 'string" unless\
      push_notification.subject and push_notification.subject.class == String
    raise "must have value 'body' with value 'string" unless\
      push_notification.body and push_notification.subject.class == String
    raise "must have value 'registration_type' with value APNS" unless\
     push_notification.registration_type and push_notification.registration_type == "APNS"
    raise "must have value 'registration_id' with value string" unless\
       push_notification.registration_id and push_notification.registration_id.class == String

    registration_id = push_notification.registration_id # an array of one or more client registration tokens
    total_unread_push_notifications = push_notification.organisation_address.unread_push_notifications+1 rescue 1

    payload = {
      notifications: [
        {
          tokens: [registration_id],
          platform: 1,
          alert: {
            title: push_notification.subject,
            body: push_notification.body,
          },
          badge: total_unread_push_notifications, 
          "sound": {
            "critical": 1,
            "name": "ding.caf",
            "volume": 2.0
          },
          topic: push_notification.organisation.bundle_id
        }
      ]
    }

    organisation = push_notification.organisation ? push_notification.organisation : push_notification.festival.organisation

    # Check if the current app for this organisation supports data_notifications, if it does, include them.  
    if organisation.send_data_notifications
      # This flag is required for the push notification payload to be handled when the app 
      # is open after recieving a push in the background.
      payload[:notifications][0][:content_available] = true
    end

    payload = self.data(payload, push_notification)

    begin  
      unless dry_run       
        GorushService.send(payload, push_notification.organisation_id)   
        push_notification.send_notification!
      else
        puts "DRY RUN - (#{payload}) \n\n push_notification.update! pushed_state: :sent, sent_at: #{DateTime.now}"
      end
    rescue Exception => e
      push_notification.update! pushed_state: :failed, push_error: e
      raise "error sending message --> #{e}"
    end
  end

  # Make an a request ot the GoRush server to send a batch of apns notification
  # push_notification   PushNotification ActiveRecord Object (ActiveRecord object)
  # dry_run             Set to true to test without sending the request to GoRush
  def self.make_batch_apns_request batch_of_notifications, dry_run=false
    # The in_groups_of function above creates nil values for notifications, this removes the
    # nil values from the array.
    batch_of_notifications = batch_of_notifications.compact

    raise "must have value 'registration_type' with value APNS" unless\
      batch_of_notifications.collect {|pn| pn.registration_type}.uniq === ['APNS']

    organisation_ids = batch_of_notifications.collect {|pn| "#{pn.organisation_id}"}.uniq

    raise "all notifications must have the same organisation_id" unless\
      organisation_ids.count === 1

    # Collect all registration_ids for all notifications in this batch
    registration_ids = batch_of_notifications.collect{|pn| pn.registration_id }

    # The bundle id is set in the config.xml file in the cordova project for each app.  
    # topic = ENV['RAILS_ENV'] === 'development' ? 'com.rover.boma' : push_notification.festival.bundle_id

    bundle_id = batch_of_notifications[0].festival ? batch_of_notifications[0].festival.bundle_id : batch_of_notifications[0].organisation.bundle_id

    payload = {
      notifications: [
        {
          tokens: registration_ids,
          platform: 1,
          alert: {
            title: batch_of_notifications[0].subject,
            body: batch_of_notifications[0].body,
          },
          badge: batch_of_notifications[0].unread_push_notifications, 
          "sound": {
            "critical": 1,
            "name": "ding.caf",
            "volume": 2.0
          },
          topic: bundle_id
        },
      ]
    }

    organisation = batch_of_notifications[0].organisation ? batch_of_notifications[0].organisation : batch_of_notifications[0].festival.organisation

    # Check if the current app for this organisation supports data_notifications, if it does, include them.  
    if organisation.send_data_notifications
      # This flag is required for the push notification payload to be handled when the app 
      # is open after recieving a push in the background.
      payload[:notifications][0][:content_available] = true
    end

    payload = self.data(payload, batch_of_notifications[0])

    begin  
      unless dry_run    
        GorushService.send(payload, batch_of_notifications[0].organisation_id)   
        self.update_pushed_state batch_of_notifications, :sent
      else
        puts "DRY RUN - (#{payload}) \n\n push_notification.update! pushed_state: :sent, sent_at: #{DateTime.now}"
      end
    rescue Exception => e
      self.update_pushed_state batch_of_notifications, :failed, e
      raise "error sending message --> #{batch_of_notifications[0]} - #{e}"
    end
  end

  # Make an a request ot the GoRush server to send one fcm notification
  #
  # The payload includes two messages, one which triggers a notification (message in notificaitons tray and sound)
  # and another which delivers the data payload to keep the messages saved in the client local storage in sync.  
  #
  # push_notification   PushNotification ActiveRecord Object (ActiveRecord object)
  # dry_run             Set to true to test without sending the request to GoRush
  def self.make_fcm_request push_notification, dry_run=false
    raise "must have value 'subject' with value 'string" unless\
      push_notification.subject and push_notification.subject.class == String
    raise "must have value 'body' with value 'string" unless\
      push_notification.body and push_notification.subject.class == String
    raise "must have value 'registration_type' with value FCM" unless\
     push_notification.registration_type and push_notification.registration_type == "FCM"
    raise "must have value 'registration_id' with value string" unless\
       push_notification.registration_id and push_notification.registration_id.class == String

    registration_id = push_notification.registration_id # an array of one or more client registration tokens

    payload = {
      notifications: [
        # The first object triggers a notification to be included in the notification tray and a ding
        {
          tokens: [registration_id],
          platform: 2,
          android_channel_id: "boma_notification",
          notification: {
            title: push_notification.subject,
            body: push_notification.body,
            android_channel_id: "boma_notification",
            click_action: "com.adobe.phonegap.push.background.MESSAGING_EVENT"
          },
          content_available: true,
          priority: 'high',
          expiration: (DateTime.now + 12.hours).to_i,
        },
      ]
    }

    organisation = push_notification.organisation ? push_notification.organisation : push_notification.festival.organisation

    # Check if the current app for this organisation supports data_notifications, if it does, include them.  
    if organisation.send_data_notifications
      # the second is the data payload which delivers a silent message which updates the notifications
      # stored in the client's localstorage.  
      data_notification = {
        tokens: [registration_id],
        platform: 2,
        priority: 'normal',
        expiration: (DateTime.now + 12.hours).to_i,
      }

      payload[:notifications] << data_notification
    end

    payload = self.data(payload, push_notification)

    begin  
      unless dry_run       
        GorushService.send(payload, push_notification.organisation_id)   
        push_notification.send_notification!
      else
        puts "DRY RUN - (#{payload}) \n\n push_notification.update! pushed_state: :sent, sent_at: #{DateTime.now}"
      end
    rescue Exception => e
      push_notification.update! pushed_state: :failed, push_error: e
      raise "error sending message --> #{e}"
    end
  end

  # Make an a request ot the GoRush server to send a batch of fcm notification
  # push_notification   PushNotification ActiveRecord Object (ActiveRecord object)
  # dry_run             Set to true to test without sending the request to GoRush
  def self.make_batch_fcm_request batch_of_notifications, dry_run=false
    # The in_groups_of function above creates nil values for notifications, this removes the
    # nil values from the array.
    batch_of_notifications = batch_of_notifications.compact

    raise "must have value 'registration_type' with value FCM" unless\
      batch_of_notifications.collect {|pn| pn.registration_type}.uniq === ['FCM']

    organisation_ids = batch_of_notifications.collect {|pn| "#{pn.organisation_id}"}.uniq

    raise "all notifications must have the same organisation_id" unless\
      organisation_ids.count === 1

    registration_ids = batch_of_notifications.collect{|pn| pn.registration_id }

    payload = {
      notifications: [
        {
          tokens: registration_ids,
          platform: 2,
          android_channel_id: "boma_notification",
          notification: {
            title: batch_of_notifications[0].subject,
            body: batch_of_notifications[0].body,
            android_channel_id: "boma_notification",
            click_action: "com.adobe.phonegap.push.background.MESSAGING_EVENT"
          },
          content_available: true,
          priority: 'high',
          time_to_live: (DateTime.now + 12.hours).to_i - DateTime.now.to_i, #12 hours in seconds
        },
      ]
    }

    organisation = batch_of_notifications[0].organisation ? batch_of_notifications[0].organisation : batch_of_notifications[0].festival.organisation

    # Check if the current app for this organisation supports data_notifications, if it does, include them.  
    if organisation.send_data_notifications
      # the second is the data payload which delivers a silent message which updates the notifications
      # stored in the client's localstorage.  
      data_notification = {
        tokens: registration_ids,
        platform: 2,
        priority: 'normal',
        expiration: (DateTime.now + 12.hours).to_i,
      }

      payload[:notifications] << data_notification
    end

    payload = self.data(payload, batch_of_notifications[0])

    begin  
      unless dry_run
        GorushService.send(payload, batch_of_notifications[0].organisation_id)   
        self.update_pushed_state batch_of_notifications, :sent
      else
        puts "DRY RUN - (#{payload}) \n\n push_notification.update! pushed_state: :sent, sent_at: #{DateTime.now}"
      end
    rescue Exception => e
      self.update_pushed_state batch_of_notifications, :failed, e
      raise "error sending message --> #{batch_of_notifications[0]} - #{e}"
    end
  end

  # Send a push notification using the legacy FCM system. 
  # push_notification   PushNotification ActiveRecord Object (ActiveRecord object)
  # dry_run             Set to true to test without sending the request to GoRush
  def self.make_personalised_fcm_request push_notification, dry_run=false
    raise "must have value 'subject' with value 'string" unless\
      push_notification.subject and push_notification.subject.class == String
    raise "must have value 'body' with value 'string" unless\
      push_notification.body and push_notification.subject.class == String
    raise "must have value 'registration_type' with value LEGACY_FCM" unless\
     push_notification.registration_type and push_notification.registration_type == "LEGACY_FCM"
    raise "must have value 'registration_id' with value string" unless\
       push_notification.registration_id and push_notification.registration_id.class == String

    fcm = Fcmpush.new(ENV['GOOGLE_PROJECT_ID'])

    registration_id = push_notification.registration_id # an array of one or more client registration tokens

    total_unread_push_notifications = push_notification.organisation_address.unread_push_notifications+1 rescue 1

    curl_attrs = { # ref. https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages
      message: {
        token: registration_id,
        notification:{
          title: push_notification.subject,
          body: push_notification.body,
        },
        android: {
          notification: {
            channel_id: "boma_notification"
          }
        },
        # priority:"high",
        # restricted_package_name:"",
        
        "apns": {
          "payload": {
            "aps": {
              "badge": total_unread_push_notifications,
              "sound": "ding.caf"
            }
          }
        },
        data:{
          api_notification_id: push_notification.id.to_s,
        },
      },
    }
    
    if(push_notification.article)
      curl_attrs[:message][:data][:article_type] = push_notification.article.article_type.to_s
      curl_attrs[:message][:data][:article_id] = push_notification.article.id.to_s
      curl_attrs[:message][:data][:article_tags] = push_notification.article.tags.collect(&:id).to_s
    end

    if(push_notification.event)
      curl_attrs[:message][:data][:event_type] = push_notification.event.event_type.to_s
      curl_attrs[:message][:data][:event_id] = push_notification.event.id.to_s
    end

    if(push_notification.stream)
      curl_attrs[:message][:data][:stream] = push_notification.stream.to_s
    end

    begin  
      unless dry_run       
        begin
          response = fcm.push(curl_attrs)
          push_notification.send_notification!
        rescue Fcmpush::Forbidden => e
          push_notification.update! pushed_state: :failed, push_error: e
          push_notification.address.organisation_address_from_festival_id(push_notification.festival_id).delete
          puts "Fcmpush::Forbidden for #{push_notification.id}, notifcation unsent"
        rescue Fcmpush::NotFound => e 
          push_notification.update! pushed_state: :failed, push_error: e
          push_notification.address.organisation_address_from_festival_id(push_notification.festival_id).delete
          puts "Fcmpush::NotFound for #{push_notification.id}, notifcation unsent"
        rescue Exception => e
          push_notification.update! pushed_state: :failed, push_error: e
          puts e.inspect
        end      
      else
        puts "DRY RUN - response = fcm.push(#{curl_attrs}) \n\n push_notification.update! pushed_state: :sent, sent_at: #{DateTime.now}"
      end
    rescue Exception => e
      push_notification.update! pushed_state: :failed, push_error: e
      raise "error sending message --> #{e}"
    end
  end

  # Set the data section of the notification payload to control how the notification is handled when the notification is 
  # clicked and the app opens
  # payload             The payload as it current exists (passed through from make_apns_request, make_batch_apns_request, make_fcm_request, make_batch_fcm_request) (object)
  # push_notification   PushNotification ActiveRecord Object (ActiveRecord object)
  def self.data payload, push_notification
    payload[:notifications].each_with_index do |n, index|
      payload[:notifications][index][:data] = {}
      payload[:notifications][index][:data]['content-available'] = 1
      payload[:notifications][index][:data][:api_notification_id] = push_notification.id.to_s
      payload[:notifications][index][:data][:festival_id] = push_notification.festival_id.to_s

      # Left in for backwards compatibility but can be removed once all apps are updated.  
      # IMPORTANT:  If included in silent/backgrounds notification then the push plugin interprets these are the 
      # attributes neccesary to create a foreground notification.  
      unless index > 0
        payload[:notifications][index][:data][:subject] = push_notification.subject
        payload[:notifications][index][:data][:body] = push_notification.body
      end

      # Used to populate the notification model on the app client
      payload[:notifications][index][:data][:notification_subject] = push_notification.subject
      payload[:notifications][index][:data][:notification_body] = push_notification.body

      if(push_notification.article)
        payload[:notifications][index][:data][:article_type] = push_notification.article.article_type.to_s
        payload[:notifications][index][:data][:article_id] = push_notification.article.id.to_s
        payload[:notifications][index][:data][:article_tags] = push_notification.article.tags.collect(&:id).to_s
      end

      if(push_notification.event)
        payload[:notifications][index][:data][:event_type] = push_notification.event.event_type.to_s
        payload[:notifications][index][:data][:event_id] = push_notification.event.id.to_s
      end

      if(push_notification.stream)
        payload[:notifications][index][:data][:stream] = push_notification.stream.to_s
      end

      if(push_notification.message_id)
        payload[:notifications][index][:data][:api_message_id] = push_notification.message_id.to_s
      end
    end

    return payload
  end
end