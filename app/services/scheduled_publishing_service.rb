class ScheduledPublishingService

  # ---------------------------------------------------- #
  # --------------- Scheduled Articles ----------------- #
  # ---------------------------------------------------- #

  # Publish articles that has been scheduled for later.  
  # This method is called via a cron via the rake command `rake publish_scheduled_articles`
  def publish_scheduled_articles
    Organisation.all.each do |organisation|
      telegram_message = ""

      now_articles = AppData::Article.where("organisation_id = ? OR festival_id IN (?)", organisation.id, organisation.festivals.ids).where(aasm_state: :draft).where('publish_at > ? AND publish_at < ?', DateTime.now.beginning_of_hour, DateTime.now.end_of_hour)

      if(now_articles.count > 0)    
        telegram_message = "<strong>The following articles have just been published by a scheduled job </strong> \n\n"
   
        now_articles.each do |article|
          telegram_message = telegram_message + " - #{article.title} \n"
          article.publish!
        end
      end

      next_articles = AppData::Article.where("organisation_id = ? OR festival_id IN (?)", organisation.id, organisation.festivals.ids).where(aasm_state: :draft).where('publish_at > ? AND publish_at < ?', DateTime.now.beginning_of_hour + 1.hour, DateTime.now.end_of_hour  + 1.hour)

      if(next_articles.count > 0)
        telegram_message = telegram_message + "\n<strong>The following articles are scheduled to be published in 1 hour</strong> \n\n"

        next_articles.each do |article|
          telegram_message = telegram_message + " - <strong>#{article.title}</strong> \n"
        end
      end

      TelegramService.new(organisation).send_message_to_group(telegram_message) if telegram_message != ""
    end
  end

end