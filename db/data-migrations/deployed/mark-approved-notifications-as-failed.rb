PushNotification.where(pushed_state: :approved).in_groups_of(1000, false).each_with_index do |approved_notifications, index|
  puts "Updating batch ##{index}"
  PushNotificationsService.update_pushed_state(approved_notifications, :failed)
  puts "Updated batch ##{index}"
end