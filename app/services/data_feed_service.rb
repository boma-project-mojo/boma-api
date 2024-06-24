# Data Feed Service
#
# This service provides methods to expose the festival schedule as JSON to allow integration by other
# developers into third party applications.  For more information see https://gitlab.com/boma-hq/boma-api#json-data-feed

class DataFeedService

  attr_accessor :output

  # Collect all of the elements of the festival schedule and serialise it for display or export.  
  # Params:
  # +festival+:: An ActiveRecord Festival object 
  def initialize(festival)
    # @path_to_images = Rails.root.join('../client/public', 'content/images/')
    # @path_to_venue_images = Rails.root.join('../client/public', 'content/images/', 'venues')

    productions = AppData::Production.where(festival_id: festival.id).published
    productions_hash = []
    event_ids = []
    productions.each do |p| 
      productions_hash.push(Feed::ProductionSerializer.new(p).to_hash)
      event_ids += p.events.map{|e| e.id}
    end

    events = AppData::Event.where(festival_id: festival.id).published.where(id: event_ids)
    events_hash = []
    venue_ids = []    
    events.each do |e| 
      events_hash.push(Feed::EventSerializer.new(e).to_hash)
      venue_ids.push e.venue.id
    end

    venues = AppData::Venue.where(festival_id: festival.id).published
    venues_hash = []
    venues.each do |v| 
      venues_hash.push(Feed::VenueSerializer.new(v).to_hash)
    end    

    tags = AppData::Tag.where(festival_id: festival.id)
    tags_hash = []
    tags.each do |t| 
      tags_hash.push(Feed::TagSerializer.new(t).to_hash)
    end    


    @output = {
      manifest: {
        last_updated: DateTime.now,
        last_updated_timestamp: DateTime.now.to_i
      },
      existing_root: {
        productions: productions_hash,
        events: events_hash,
        venues: venues_hash,
        tags: tags_hash
      }
    }


  end

  # Return the schedule as a hash
  def to_hash
    @output.to_hash
  end

  # Return as formatted JSON.  
  def to_pretty_json
    JSON.pretty_generate(@output)
  end
end
