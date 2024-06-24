# Wordpress Data Service
#
# This service provides an interface to import Articles and Venues, Tags, Productions and Events 
# from a wordpress API.  It is currently configured to use the schema that is provided for Greenbelt
# buc could easily be amended to accommodate a standardised or configurable schema.  

class WordpressDataService

  # Initialises the WordpressDataService
  # Params:
  # +base+:: The base URL for the API e.g https://somewordpresswebsite.org.uk/wp-json/wp/v2/
  # +festival_id+:: Our ID for the festival
  def initialize base=nil, festival_id
    @base = base
    @festival = Festival.find(festival_id)

    @processed_source_ids = {}
  end

  def valid_url?(uri)
    uri = URI.parse(uri)
    uri.is_a?(URI::HTTP) && !uri.host.nil?
  rescue URI::InvalidURIError
    false
  end

  # Sends the request to get the data from the API
  # Params:
  # +endpoint+:: The URL to send the request to
  # +currentpage+:: The currentpage being requested.  
  # +params+:: An object of query params to be sent with the request. 
  def get_payload endpoint, currentpage, params={}
    # Add page, per_page and order to the params object
    all_params = params.merge({
      page: currentpage,
      per_page: 100,
      order: 'desc'
    })

    # Send the request to the API
    request = URI.open(@base+endpoint+"/?_embed&"+URI.encode_www_form(all_params)) do |f| 
      @response = {
        response: JSON.parse(f.read),
        metadata: f.meta
      } 
    end

    # Logging
    puts "Processing page #{currentpage} for #{endpoint} (#{@base+endpoint+"/?_embed&"+URI.encode_www_form(all_params)})"

    # Return the API response.  
    return @response
  end

  # Creates tags for each fo the records which are returned from the specified endpoint
  # Params:
  # +args+:: An object of arguments is used for pagination of the API.  
  # +params+:: An object of params to be sent to the API endpoint.  
  def create_tags args, params={}
    raise "ERROR:  arguments must include `endpoint`" unless args[:endpoint]
    raise "ERROR:  arguments must include `tag_type`" unless args[:tag_type]

    # Request the payload from the API endpoint.  
    payload = self.get_payload(args[:endpoint], args[:currentpage] || 1, params)

    # For each item in the API response...
    payload[:response].each do |tag|
      # Only import tags where 'genre_is_current' is set to true.  
      #
      # The 'categoires' endpoint which is used for Talks, Blog and Podcast feeds (see rake import_date:greenbelt_article_data_2020) 
      # doesn't have 'custom_fields' implemented to check the tag is being used currently.  It is safe to assume all are current and 
      # should be processed.  .  
      if args[:endpoint] === 'categories' or (tag["custom_fields"] and tag["custom_fields"]["genre_is_current"])
        source_id = tag["id"]

        # Find the existing tag or initialise a new object.  
        @tag = @festival.tags.where(source_id: source_id).where(tag_type: args[:tag_type]).first_or_initialize
        # Update attributes
        @tag.name = tag["name"]
        @tag.festival_id = @festival.id
        @tag.source_id = source_id
        # Save the record.  
        self.save_record @tag
      end
    end

    # Construct the arguments for the next page 
    args = {
      currentpage: args[:currentpage] || 1,
      apimethod: method(:create_tags),
      endpoint: args[:endpoint],
      tag_type: args[:tag_type]
    }

    # Process the next page of results
    self.next_page(payload, args, params)
  end

  def create_articles args, params={}
    raise "ERROR:  arguments must include `endpoint`" unless args[:endpoint]
    raise "ERROR:  arguments must include `article_type`" unless args[:article_type]
    raise "ERROR:  arguments must include `taxonomy_name`" unless args[:taxonomy_name]

    payload = self.get_payload(args[:endpoint], args[:currentpage] || 1, params)

    payload[:response].each do |article|
      source_id = article["id"]
      
      # If this is an audio article but doesn't have an audio link then ignore it
      if args[:article_type] === 'boma_audio_article' and (article['acf']['talk_audio_file'].nil? or article['acf']['talk_audio_file'] === "")
        next false
      end

      @article = @festival.articles.where(source_id: source_id).first_or_initialize
      @article.title = CGI.unescapeHTML(article["title"]["rendered"])

      # Adding target=_blank here as not doing so triggers an unnecessary saving and then updating of records once 
      # this process is completed by the callback in base.rb
      @article.content = (CGI.unescapeHTML(article["content"]["rendered"]).gsub(/<a (?!target)/, '<a target="_blank" ') rescue nil)

      # Glue code for Greenbelt as we currently do not support multiple categories per model and metadata / associating 
      # articles with AppData::Person or AppData::Production isn't supported
      if args[:article_type] === 'boma_audio_article' and @festival.id === 5
        additional_content = "
          <p>
            <strong>Speaker name: #{article['acf']['talk_artists_text']}</strong><br/>
            <strong>Year: #{article['acf']['talk_festival_year']}</strong>
          </p>
          "
        @article.content = @article.content + additional_content
      end

      @article.organisation_id = @festival.organisation.id
      @article.festival_id = @festival.id
      @article.source_id = source_id

      @article.article_type = args[:article_type] if args[:article_type]

      if article['acf'] && article['acf']['talk_audio_file']
        @article.audio_url = article['acf']['talk_audio_file']
      end

      if article['_embedded']['wp:featuredmedia'] and article['_embedded']['wp:featuredmedia'][0]['source_url']
        URI.open(article['_embedded']['wp:featuredmedia'][0]['source_url']) do |file|
          @article = setup_record_image(@article, nil, file) 
        end
      elsif
        # Scrape image from site
        begin
          article_page = Nokogiri.HTML(URI.open(article["link"]))  
          URI.open(article_page.at('.artist-image')['src']) do |file|
            @article = setup_record_image(@article, nil, file) 
          end 
        rescue 
          "No image available for #{article['link']}"
        end
      end


      if(article['acf'] && article['acf']['talk_featured'])
        @article.featured = article['acf']['talk_featured']
      end

      if(article['acf'] && article['acf']['talk_festival_year'])
        set_meta(@article, 'talk_festival_year', article['acf']['talk_festival_year'].to_i)
      end

      if(article['acf'] && article['acf']['talk_artists_text'])
        set_meta(@article, 'talk_artists_text', article['acf']['talk_artists_text'])
      end

      @article = self.set_tags(@article, article, args[:taxonomy_name]) if article['_embedded']['wp:term']

      @article = self.set_created_at @article, article

      self.save_record @article
    end

    args = {
      currentpage: args[:currentpage] || 1,
      apimethod: method(:create_articles),
      endpoint: args[:endpoint],
      maxpage: args[:maxpage],
      taxonomy_name: args[:taxonomy_name],
      article_type: args[:article_type]
    }

    self.next_page(payload, args, params)
  end

  # Creates venues for each fo the records which are returned from the specified endpoint
  # Params:
  # +args+:: An object of arguments is used for pagination of the API.  
  # +params+:: An object of params to be sent to the API endpoint.   
  def create_venues args, params={}
    raise "ERROR:  arguments must include `endpoint`" unless args[:endpoint]
    raise "ERROR:  arguments must include `venue_type`" unless args[:venue_type]

    # Request the payload from the API endpoint.  
    payload = self.get_payload(args[:endpoint], args[:currentpage] || 1, params)

    # For each item in the API response...
    payload[:response].each do |venue|
      source_id = venue["id"]
      
      # Find the existing record or initialise a new object.  
      @venue = @festival.venues.where(source_id: source_id).first_or_initialize
      
      # If a the 'venue_is_public' attribute is true
        # process the record
      # else
       # delete it if we have a saved record
      if venue['custom_fields']['venue_is_public'] === true
        # Unescape the HTML and set the venue name 
        @venue.name = CGI.unescapeHTML(venue["title"]["rendered"])

        # Allow empty venue descriptions if necessary.  
        description = venue["content"]["rendered"].empty? ? "⠀" : venue["content"]["rendered"]
        # Adding target=_blank here as not doing so triggers an unneccesary saving and then updating of records once 
        # this process is completed by the callback in base.rb
        @venue.description = (CGI.unescapeHTML(description).gsub(/<a (?!target)/, '<a target="_blank" ') rescue nil)
        @venue.festival_id = @festival.id
        @venue.source_id = source_id
        @venue.venue_type = args[:venue_type]
        @venue.list_order = venue['custom_fields']['venue_order']

        # if an image is provided for the venue
          # use it
        # otherwise
          # use a placeholder image
        if venue['_embedded'] and venue['_embedded']['wp:featuredmedia']
          @venue = setup_record_image(@venue, venue['_embedded']['wp:featuredmedia'][0]['source_url']) 
        else
          puts "Using a placeholder image for #{@venue.name}"
          @venue = setup_record_image(@venue, "https://www.greenbelt.org.uk/wp-content/uploads/2023/02/G23-Themeprint.jpg") 
        end

        # If tags are available for this record then set the tags for this record.  
        @venue = self.set_tags(@venue, venue, args[:taxonomy_name]) if(venue['_embedded'] and venue['_embedded']['wp:term'])
        # Mirror our created_at date with the date on the API record.  
        @venue = self.set_created_at @venue, venue
        # Save the record.  
        self.save_record @venue
      else
        # if the record has been removed from the API delete it.  
        unless @venue.new_record?
          puts "Deleting #{@venue.name}"
          @venue.unpublish! unless @venue.draft?
        end
      end
    end

    # Construct the args for the next_page
    args = {
      currentpage: args[:currentpage] || 1,
      apimethod: method(:create_venues),
      endpoint: args[:endpoint],
      maxpage: args[:maxpage],
      taxonomy_name: args[:taxonomy_name],
      venue_type: args[:venue_type]
    }
    # Request the next page.  
    self.next_page(payload, args, params)
  end

  # Creates productions for each fo the records which are returned from the specified endpoint
  # Params:
  # +args+:: An object of arguments is used for pagination of the API.  
  # +params+:: An object of params to be sent to the API endpoint.   
  def create_productions args, params={}
    raise "ERROR:  arguments must include `endpoint`" unless args[:endpoint]

    # Request the payload from the API endpoint.  
    payload = self.get_payload(args[:endpoint], args[:currentpage] || 1, params)

    # For each item in the API response...
    payload[:response].each do |production|
      # to get artist record, e.g https://dev.greenbelt.org.uk/wp-json/wp/v2/marcato_artist/174265
      # artist = self.get_payload(production["_links"]["self"][0]["href"].gsub(@base,''), 0)

      source_id = production["id"]

      # Find the existing record or initialise a new object.  
      @production = @festival.productions.where(source_id: source_id).first_or_initialize
      # Unescape the HTML and set the name 
      @production.name = CGI.unescapeHTML(production["title"]["rendered"])

      # Adding target=_blank here as not doing so triggers an unnecessary saving and then updating of records once 
      # this process is completed by the callback in base.rb
      description = production["content"]["rendered"].empty? ? "⠀" : production["content"]["rendered"]
      @production.description = (CGI.unescapeHTML(description).gsub(/<a (?!target)/, '<a target="_blank" ') rescue nil)
      @production.festival_id = @festival.id
      @production.source_id = source_id

      # if an image is provided for the venue
        # use it
      # otheriwse
        # use a placeholder image
      if production['custom_fields']['artist_image']
        @production = setup_record_image(@production, production['custom_fields']['artist_image']) 
      else
        @production = setup_record_image(@production, "https://dev.greenbelt.org.uk/wp-content/uploads/2020/04/G-Logo-Red-1.jpg")
      end

      # Use the 'set_meta' to store the artist_image_caption
      set_meta(@production, 'artist_image_caption', production['custom_fields']['artist_image_caption']) if production['custom_fields']['artist_image_caption']

      # Use the 'set_meta' to store the 'artist_websites' 
      if production['acf']['artist_websites']
        production['acf']['artist_websites'].each do |artist_website|
          if valid_url?(artist_website['artist_website_url'])
            set_meta(@production, artist_website['artist_website_name'].parameterize, artist_website['artist_website_url'])
          else
            puts "Invalid url #{artist_website['artist_website_url']}"
          end
        end
      end

      # Set the tags for this production.  
      production['_embedded']['wp:term'][0].each do |tag|
        t = @festival.tags.where(tag_type: :production).find_by_source_id(tag['id'])
        @production.tags << t unless t.nil? or @production.tags.include? t
      end

      # Mirror our created_at date with the date on the API record.  
      @production = self.set_created_at @production, production

      # Save the record.  
      self.save_record @production
    end

    # Construct the args for the next_page
    args = {
      currentpage: args[:currentpage] || 1,
      apimethod: method(:create_productions),
      endpoint: args[:endpoint],
      maxpage: args[:maxpage],
      taxonomy_name: args[:taxonomy_name],
    }
    # Request the next page.  
    self.next_page(payload, args, params)
  end

  # Creates events for each fo the records which are returned from the specified endpoint
  # Params:
  # +args+:: An object of arguments is used for pagination of the API.  
  # +params+:: An object of params to be sent to the API endpoint.   
  def create_events args, params={}
    raise "ERROR:  arguments must include `endpoint`" unless args[:endpoint]

    # Request the payload from the API endpoint.  
    payload = self.get_payload(args[:endpoint], args[:currentpage] || 1, params)

    # For each item in the API response...
    payload[:response].each do |event|
      source_id = event["id"]

      # Find the existing record or initialise a new object.  
      @event = @festival.events.where(source_id: source_id).first_or_initialize

      # If a the 'show_is_public' attribute is true
        # process the record
      # else
        # delete it if we have a saved record
      if event['acf']['show_is_public']
        # Unescape the HTML and set the name 
        @event.name = CGI.unescapeHTML(event["title"]["rendered"])

        # # Adding target=_blank here as not doing so triggers an unneccesary saving and then updating of records once 
        # # this process is completed by the callback in base.rb
        @event.description = (CGI.unescapeHTML(event["content"]["rendered"]).gsub(/<a (?!target)/, '<a target="_blank" ') rescue nil)
        @event.festival_id = @festival.id
        @event.source_id = source_id

        # If the venue this event takes place at.  
        @event.venue = @festival.venues.find_by_source_id(event['acf']['show_venue'])
        
        # Parse the start_time and end time into the right format and timezone and set them on the ActiveRecord object
        @event.start_time = DateTime.parse("#{event['acf']['show_date']} #{event['acf']['show_start_time']} GMT+1") if(event['acf']['show_date'] and event['acf']['show_start_time'])
        @event.end_time = DateTime.parse("#{event['acf']['show_end_date']} #{event['acf']['show_end_time']} GMT+1") if(event['acf']['show_date'] and event['acf']['show_end_time'])

        # Take a copy of the production_ids before processing productions, this is used
        # to identify if productions have changed and if so triggers couchdb records to refresh
        productions_changed = false
        existing_production_ids = @event.production_ids

        # if the event is new to use
          # add each of the related productions to the event
          # if it has no productions then log that.  
        # else if this is an existing record
          # collect the production ids and add these to the record.  

        # This is necessary as adding the productions using the << method 
        # does not work with existing records (and vice versa).
        if @event.new_record?
          if event["custom_fields"]["related_artists"]
            event["custom_fields"]["related_artists"].each do |production_id|
              production = @festival.productions.find_by_source_id("#{production_id}")
              @event.productions << production unless production.nil? or @event.productions.include? production
            end
          else
            puts "#{@event} (#{source_id}) has no productions"
          end
        else
          if event["custom_fields"]["related_artists"]
            production_ids = []

            event["custom_fields"]["related_artists"].each do |production_id|
              production = @festival.productions.find_by_source_id("#{production_id}")
              if production
                production_ids << production.id
              else
                puts "Production #{production_id} is missing for #{source_id}"
              end  
            end

            @event.production_ids = production_ids
          else
            puts "#{@event} (#{source_id}) has no productions"
          end
        end

        # If productions have changed set productions_changed to true 
        # so that save_record calls save on them and the associated couchdb record is renewed. 
        if existing_production_ids != @event.production_ids
          productions_changed = true
        end

        # Add tags to the record.  
        event['marcato_genre'].each do |tag|
          t = @festival.tags.where(tag_type: :event).find_by_source_id(tag)
          @event.event_tags << t unless t.nil? or @event.event_tags.include? t
        end

        # Save the record
        self.save_record @event, productions_changed
      else
        # if the record has been removed from the API delete it.  
        unless @event.new_record?
          puts "Deleting #{@event.name}"
          @event.destroy!
        end          
      end
    end

    # Construct the args for the next_page
    args = {
      currentpage: args[:currentpage] || 1,
      apimethod: method(:create_events),
      endpoint: args[:endpoint],
      maxpage: args[:maxpage],
      taxonomy_name: args[:taxonomy_name],
    }
    # Request the next page.  
    self.next_page(payload, args, params)    
  end

  # Constructs and sends the request to get the next page of results
  # Params:
  # +payload+::  The payload from the previous request sent.  
  # +args+:: An object of arguments used for pagination of the API.  
  # +params+:: An object of params to be sent to the API endpoint.  
  def next_page payload, args, params
    # Unless there is no next page
    unless payload[:metadata]['x-wp-totalpages'].to_i === args[:currentpage] or args[:maxpage] === args[:currentpage]
      # Increment the page number by 1
      args[:currentpage] = args[:currentpage]+1
      # Call the method on this service with the args and any params to 
      args[:apimethod].call(args, params)
    end
  end

  # Sets up the record image to be uploaded by carrierwave once saved
  # +record+::  An ActiveRecord model
  # +image_url+:: The URL to the image for this record
  # +file+:: A File object for the image for this record
  def setup_record_image record, image_url, file=nil
    if image_url and !self.same_image?(record.image.url, image_url)
      record.remote_image_url = image_url
      record.image_last_updated_at = DateTime.now
    elsif file and !self.same_image?(record.image.url, file)
      record.image = file
      record.image_last_updated_at = DateTime.now
    end
    return record
  end

  # Mirror our 'created_at date with that of the record. 
  # +record+::  An ActiveRecord model
  # +payload+:: The API payload.
  def set_created_at record, payload
    record.created_at = payload['date']

    return record
  end

  # Sets up the tags for this record ready to be persisted 
  # +record+::  An ActiveRecord model
  # +image_url+:: The URL to the image for this record
  # +file+:: A File object for the image for this record
  def set_tags record, payload, taxonomy_name
    # for each of the records in the payload for this 'taxonomy_name' 
    payload[taxonomy_name].each do |tag_source_id|
      # unless the record already has the tag 
      unless record.tags.find_by_source_id(tag_source_id)
        # add the tag to the record 
        record.tags << @festival.tags.find_by_source_id(tag_source_id)
      end
    end
    # return the record
    return record
  end

  # Meta data can be recorded on the 'meta' attribute on the ActiveRecord model, this is a JSON attr
  # +record+::  An ActiveRecord model
  # +attr_name+:: A string representing the name of the attribute to store. 
  # +value+:: The value to be stored.
  def set_meta record, attr_name, value
    # if there is no existing mate, 
      # create the object from scratch
    # else if there is meta but there is no value for this attr_name
      # update the meta to include this attribute name
    # else if there is meta and there is a value for this attr_name
      # update the value.  
    if record.meta.nil?
      record.meta = {"#{attr_name}": value}
    elsif record.meta && !record.meta[attr_name].nil?
      record.meta[attr_name] = value
    elsif record.meta && record.meta[attr_name].nil?
      record.meta[attr_name] = value
    end
  end

  # Returns a human readable identifer for this record (name or title)
  # Params:
  # +record+:: An ActiveRecord object to be saved.    
  def record_human_identifier record
    # If a record uses 'name' for it's human identifying term 
      # return it
    # else if a record uses 'title'
      # return it
    if record.try(:name)
      hid = record.name
    elsif record.try(:title)
      hid = record.title
    end

    return hid
  end

  # Checks for changes in the image (either URL or File object)
  # Params:
  # +path1+:: The first image 
  # +path2+:: The second image    
  def same_image?(path1, path2)
    # Return false if there is no existing image for this record.  
    return false if path1 === nil

    # Return true if the existing image matches the new image being provided.  
    return true if path1 == path2

    begin
      # Open the URI for the stored image
      URI.open(path1) {|image1| 
        # If 'path2' is a File object
          # compare the size and the image content looking for changes
        # else
          # open the URI and compare the size and the image content looking for changes
        if(path2.class === Tempfile)
          image2 = path1
          # If image sizes aren't identical assume the file has changed
          return false if image1.size != image2.size
          # Check bites are ientical, if not return false.  
          while (b1 = image1.read(1024)) and (b2 = image2.read(1024))
            return false if b1 != b2
          end
        else
          URI.open(path2) {|image2|
            # If image sizes aren't identical assume the file has changed
            return false if image1.size != image2.size
            # Check bites are ientical, if not return false.  
            while (b1 = image1.read(1024)) and (b2 = image2.read(1024))
              return false if b1 != b2
            end
          }
        end
      }
      # return true if no changes have been found
      true
    rescue Exception => e
      puts e
      # as a failsafe return true and just update the image
      true
    end
  end

  # Save a record
  # Params:
  # +record+:: An ActiveRecord object to be saved.    
  # +productions_changed+:: Used when importing events to flag whether productions have changed and should be updated or not.  
  def save_record record, productions_changed=nil
    # Get the human identifier for this reecord for logging
    identifer = record_human_identifier(record)

    if record.changed? or productions_changed
      begin
        if record.save!
          if record.class.name === 'AppData::Event'
            record.mirror_production_published_state
          end
          @processed_source_ids[record.class.name] << record.source_id rescue @processed_source_ids[record.class.name] = [record.source_id]
          puts "INFO | #{record.class.name} #{identifer} saved | (Boma ID: #{record.id}, Source ID: #{record.source_id}) | SAVE" 
        else
          puts "FATAL | #{record.class.name} #{identifer} invalid #{record.errors.messages} | Source ID: #{record.source_id}) | FAIL"
        end
      rescue
        puts "FATAL | #{record.class.name} #{identifer} invalid #{record.errors.messages} | Source ID: #{record.source_id}) | FAIL"
      end
    else
      @processed_source_ids[record.class.name] << record.source_id rescue @processed_source_ids[record.class.name] = [record.source_id]
      puts "INFO | #{record.class.name} #{identifer} unchanged | (Boma ID: #{record.id}, Source ID: #{record.source_id}) | UNCHANGED"
    end
  end

  def publish_draft_articles
    @festival.articles.draft.each do |article|
      identifer = record_human_identifier(article)

      begin
        article.publish!
        puts "INFO | #{article.class.name} #{identifer} published | (Boma ID: #{article.id}, Source ID: #{article.source_id}) | PUBLISHED" 
      rescue 
        puts "FATAL | #{article.class.name} #{identifer} unable to publish #{article.errors.messages} | Source ID: #{article.source_id}) | FAIL"
      end
    end
  end

  # Publish any productions that are still in draft
  def publish_draft_productions
    @festival.productions.draft.each do |production|
      # Get human id for logging
      identifer = record_human_identifier(production)

      begin
        # lock and publish the productions
        production.update! aasm_state: :locked
        production.publish!
        # logging
        puts "INFO | #{production.class.name} #{identifer} published | (Boma ID: #{production.id}, Source ID: #{production.source_id}) | PUBLISHED" 
      rescue 
        # logging if error
        puts "FATAL | #{production.class.name} #{identifer} unable to publish #{production.errors.messages} | Source ID: #{production.source_id}) | FAIL"
      end
    end
  end

  # Delete tags / venues / events / productions that have been removed from the API
  def cleanup_festival_schedule
    puts "Starting cleanup..."

    puts @processed_source_ids.inspect

    # tags
    tags_recieved_from_api = @processed_source_ids['AppData::Tag']
    
    # if we processed tags 
      # calculate the tags that we have live that weren't processed in this run.  
    if tags_recieved_from_api
      tags_live = @festival.tags.where(tag_type: :production).published.collect {|a| a.source_id}
      tags_that_werent_recieved_from_api = tags_live - tags_recieved_from_api
    end

    # If there are tags that we store that weren't in the API 
      # we assume they have been deleted on the API and should be removed our end too
    if tags_that_werent_recieved_from_api and tags_that_werent_recieved_from_api.count > 0
      puts "There are #{tags_that_werent_recieved_from_api.count} tags which need to be removed, deleting them now."

      puts tags_that_werent_recieved_from_api.inspect

      tags_that_werent_recieved_from_api.each do |source_id|
        @festival.tags.find_by_source_id(source_id).destroy!
      end
    else
      puts "No tags to cleanup. "
    end

    # events
    events_recieved_from_api = @processed_source_ids['AppData::Event']
    # if we processed events 
      # calculate the events that we have live that weren't processed in this run.  
    if events_recieved_from_api
      events_live = @festival.events.published.collect {|a| a.source_id}
      events_that_werent_recieved_from_api = events_live - events_recieved_from_api
    end

    # If there are events that we store that weren't in the API 
      # we assume they have been deleted on the API and should be removed our end too
    if events_that_werent_recieved_from_api and events_that_werent_recieved_from_api.count > 0
      puts "There are #{events_that_werent_recieved_from_api.count} events which need to be removed, deleting them now."

      events_that_werent_recieved_from_api.each do |source_id|
        @festival.events.find_by_source_id(source_id).destroy!
      end
    else
      puts "No events to cleanup. "
    end

    # productions
    productions_recieved_from_api = @processed_source_ids['AppData::Production']

    # if we processed productions 
      # calculate the productions that we have live that weren't processed in this run.  
    if productions_recieved_from_api
      productions_live = @festival.productions.published.collect {|a| a.source_id}
      productions_that_werent_recieved_from_api = productions_live - productions_recieved_from_api
    end

    # If there are productions that we store that weren't in the API 
      # we assume they have been deleted on the API and should be removed our end too
    if productions_that_werent_recieved_from_api and productions_that_werent_recieved_from_api.count > 0
      puts "There are #{productions_that_werent_recieved_from_api.count} productions which need to be removed, deleting them now."

      productions_that_werent_recieved_from_api.each do |source_id|
        @festival.productions.find_by_source_id(source_id).destroy!
      end
    else
      puts "No productions to cleanup. "
    end

    # venues
    venues_recieved_from_api = @processed_source_ids['AppData::Venue']

    # if we processed venues 
      # calculate the venues that we have live that weren't processed in this run.  
    if venues_recieved_from_api
      venues_live = @festival.venues.where(venue_type: :performance).published.collect {|a| a.source_id}
      venues_that_werent_recieved_from_api = venues_live - venues_recieved_from_api
    end

    # If there are venues that we store that weren't in the API 
      # we assume they have been deleted on the API and should be removed our end too
    if venues_that_werent_recieved_from_api and venues_that_werent_recieved_from_api.count > 0
      puts "There are #{venues_that_werent_recieved_from_api.count} venues which need to be removed, deleting them now."

      venues_that_werent_recieved_from_api.each do |source_id|
        @festival.venues.find_by_source_id(source_id).destroy! rescue byebug
      end
    else
      puts "No venues to cleanup. "
    end
  end


  def cleanup_articles
    puts "Starting cleanup..."

    articles_recieved_from_api = @processed_source_ids['AppData::Article']
    articles_live = @festival.articles.published.collect {|a| a.source_id}
    articles_that_werent_recieved_from_api = articles_live - articles_recieved_from_api

    if articles_that_werent_recieved_from_api.count > 0

      # STDOUT.puts "There are #{articles_that_werent_recieved_from_api.count} articles which need to be removed, would you like to delete them now? (y/n)"

      # begin
      #   input = STDIN.gets.strip.downcase
      # end until %w(y n).include?(input)

      # if input != 'y'
      #   STDOUT.puts "Nothing deleted.  "
      #   return
      # else
        articles_that_werent_recieved_from_api.each do |article_source_id|
          @festival.articles.find_by_source_id(article_source_id).destroy!
        end
      # end
    else
      puts "Nothing to cleanup.  Done."
    end
  end

end