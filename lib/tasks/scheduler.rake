desc "Rake tasks for the heroku scheduler"

task update_token_states: :environment do
  BomaTokenService.new.update_all_token_states
end

task approve_and_send_push_notifications: :environment do
  PushNotificationsService.approve_all_drafts_and_send_in_batches
end

task send_scheduled_notifications: :environment do
  BomaMessagingService.new.send_scheduled_messages
end

task publish_scheduled_articles: :environment do
  ScheduledPublishingService.new.publish_scheduled_articles
end