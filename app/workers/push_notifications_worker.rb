class PushNotificationsWorker
  include Sidekiq::Worker

  sidekiq_options retry: false

  def perform(*args)
    PushNotificationsService.create_draft_notification_for_all_organisation_app_users(args[0])
  end
end
