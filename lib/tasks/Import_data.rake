namespace :import_data do
  task greenbelt_article_data_2020: :environment do
  	wp_data_import_service = WordpressDataService.new("http://greenbelt.org.uk/wp-json/wp/v2/", 5)

    tags_args = {
      endpoint: 'categories',
      tag_type: 'news_tag',
    }

  	# main-categories
  	wp_data_import_service.create_tags(tags_args)

  	# news, max last 100
  	news_args = {
      endpoint: 'posts',
      taxonomy_name: 'categories',
      article_type: 'boma_news_article',
      maxpage: 1,
    }

    wp_data_import_service.create_articles(news_args)

    # talks-categories
    talks_args = {
      endpoint: 'talks-category',
      tag_type: 'talks_tag',
    }

    wp_data_import_service.create_tags(talks_args)
    
    # talks
    talks_args = {
      endpoint: 'talks',
      taxonomy_name: 'talks-category',
      article_type: 'boma_audio_article'
    }

    wp_data_import_service.create_articles(talks_args)

    # publish all new records
    wp_data_import_service.publish_draft_articles

    # cleanup
    wp_data_import_service.cleanup_articles
  end

  task greenbelt_festival_data_2024: :environment do
    wp_data_import_service = WordpressDataService.new("https://greenbelt.org.uk/wp-json/wp/v2/", 98)

    # The greenbelt website has an archive or all productions and events for every festival ever, 
    # we must pass their festival id as a query param to return just results for this festival
    # for productions and events.    
    gb_festival_id = 1804

    # Greenbelt use different tags for event and production records, import both of them

    # Create production tags
    # # Genres - https://dev.greenbelt.org.uk/wp-json/wp/v2/marcato_genre
    production_tag_args = {
      endpoint: 'marcato_genre',
      tag_type: 'production'
    }

    wp_data_import_service.create_tags(production_tag_args)

    # Create event tags
    # # Genres - https://dev.greenbelt.org.uk/wp-json/wp/v2/marcato_genre
    event_tag_args = {
      endpoint: 'marcato_genre',
      tag_type: 'event'
    }

    wp_data_import_service.create_tags(event_tag_args)

    # Venues - https://dev.greenbelt.org.uk/wp-json/wp/v2/marcato_venue
    venue_args = {
      endpoint: 'marcato_venue',
      venue_type: 'performance'
    }

    wp_data_import_service.create_venues(venue_args)

    # Artists - https://dev.greenbelt.org.uk/wp-json/wp/v2/marcato_artist
    production_args = {
      endpoint: 'marcato_artist',
      taxonomy_name: 'marcato_genre',
    }

    wp_data_import_service.create_productions(production_args, {festival: gb_festival_id})

    # Shows - https://dev.greenbelt.org.uk/wp-json/wp/v2/marcato_show
    event_args = {
      endpoint: 'marcato_show',
      taxonomy_name: 'marcato_genre',
    }

    wp_data_import_service.create_events(event_args, {festival: gb_festival_id})

    # Festivals - https://dev.greenbelt.org.uk/wp-json/wp/v2/festival

    # # publish all new records
    wp_data_import_service.publish_draft_productions

    # cleanup
    wp_data_import_service.cleanup_festival_schedule
  end

end
