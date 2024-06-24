# The wallet addresses with tokens
affected_addresses = Token.where(festival_id: [1,3,52,54]).collect {|t| Address.where('lower(address) = ?', t.address.downcase).first.id rescue puts "could not find #{t.id}" }.compact

# Set festival to shambala 2023
@festival = Festival.find(54)

# Set current_user to Pete
current_user = User.find(35)

# Create a message for one address
attrs = {}
attrs[:subject] = "Token-Collectors! Please back up your token wallet!"
attrs[:body] = "Hiya, you lot! We're putting the finishing touches to the official Shambala 2023 phone app. If you've been collecting tokens (eg: badges of Shambala attendance!) through the app and don't want to lose them, you need to back up your token wallet before updating the app. Go to the app settings, click 'copy private key' and paste it somewhere for safe keeping."
attrs[:stream] = "critical-comms"
attrs[:address_id] = Address.find(affected_addresses[0]).id
attrs[:created_by] = current_user.id
attrs[:festival_id] = @festival.id
attrs[:topic] = @festival.fcm_topic_id
@message = BomaMessagingService.new_draft(attrs)

# Send the message
BomaMessagingService.new.send_message(@message)

# Loop through each address and create a draft push notification ready to be sent
affected_addresses.uniq.each do |address_id|
  address = Address.find(address_id)
  organisation_address_from_festival_id = address.organisation_address_from_festival_id(@festival.id)
  if organisation_address_from_festival_id
    PushNotificationsService.create_draft_push_notification_for_address(@message.subject, @message.body, address, @message, "critical-comms", organisation_address_from_festival_id, @message.id) rescue puts "Unable to create Push Notification for #{address.is}"
    puts "Created draft push notification for #{address.id} #{organisation_address_from_festival_id.registration_type} #{address.address}"
  else
    puts "Couldn't find an organisation address for Kambe for this Address #{address.address}"
  end
end