# Data Dump Service
#
# This service provides methods to generate a bash, CSV and XML dump of 
# the festival schedule data.  

require 'zip'

class DataDumpService

  # Generate a bash script which downloads all images. 
  # This is primarily for designers when preparing printed programmes.  
  # Params:
  # +festival+:: An ActiveRecord Festival object 
  def to_bash(festival)
    productions = AppData::Production.all

    bash = ""

    AppData::Venue.where(festival_id: festival.id).each do |v|
      bash <<  "#"+v.name+"\n\n"
      AppData::Event.where(festival_id: festival.id).published.where(venue_id:v.id).each do |e|
        p = e.production
        if p
          fn = p.name.gsub(/[^\w\s_-]+/, '')
            .gsub(/(^|\b\s)\s+($|\s?\b)/, '\\1\\2')
            .gsub(/\s+/, '_')
          st = e.start_time.strftime('%FT%H%M')
          bash << "curl #{p.image.url} > '#{e.venue.name.parameterize}-#{st}-#{fn}.#{p.image.url.split('.').last}'\n" rescue false
        end
      end
      bash <<  "\n\n\n"
    end

    return bash
  end

  # Generate a csv which includes all the schedule data for the festival.
  # Params:
  # +festival+:: An ActiveRecord Festival object 
  def to_csv(festival)
    productions = AppData::Production.where(festival_id: festival.id).published

    headers = [
      'production_id', 
      'production_name', 
      'production_short_description', 
      'production_image_name', 
      'event_start_time',
      'start_date_string', 
      'event_end_time',
      'end_date_string', 
      'venue_name'
    ]

    bash = ""

    csv_string = CSV.generate(headers: headers) do |csv|
      csv << headers
      AppData::Venue.where(festival_id: festival.id).published.each do |v|
        AppData::Event.where(festival_id: festival.id).published.where(venue_id:v.id).order(:start_time).each do |e|
          p = e.production
          csv << [p.id, p.name, p.short_description, p.image.file.filename, e.start_time.in_time_zone('Europe/London'), e.date_string_start, e.end_time.in_time_zone('Europe/London'), e.date_string_end, e.venue.name] rescue false
        end
      end
    end

  end

  # Creates a zip file which includes
  # - an xml object of the schedule for all venues
  # - an xml object for each venue including it's schedule object 
  # in the correct format for importing into indesign.  
  # The zip file is uploaded to s3 and this method returns the URL to the zip file.  
  # Params:
  # +festival+:: An ActiveRecord Festival object 
  def to_xml(festival)
    filesnames = []

    venues = festival.venues.where(aasm_state: [:published]).where(venue_type: "performance")

    all_venues_xml = Nokogiri::XML::Builder.new { |xml| 
      xml.body do
        xml.venues do
          venues.each do |venue|
            xml.venue do 
              day_events = venue.events.where(aasm_state: [:published, :cancelled]).order('start_time ASC').group_by { |e| e.filter_day }
              xml.venue_name venue.name
              day_events.each do |day|
                xml.day do 
                  xml.day_name day[0]
                  xml.events do
                    day[1].each do |event|
                      xml.event do 
                        xml.event_name event.name
                        # xml.event_start_time event.date_string_start
                        # xml.event_end_time event.date_string_end
                        xml.event_start_and_end_time "#{event.time_string_start} - #{event.time_string_end}"
                        xml.event_short_description event.short_description
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    }.to_xml
    
    filename = "#{DateTime.now}-festival-#{festival.id}-ALL-VENUES.xml"
    save_path = Rails.root.join('public', filename)
    File.open(save_path, 'wb') do |file|
      file << all_venues_xml
    end

    filesnames << filename
    
    venues_xml = {}

    venues.each do |venue|
      venues_xml[venue.name] = Nokogiri::XML::Builder.new { |xml| 
        xml.body do
          xml.venue do 
            day_events = venue.events.where(aasm_state: [:published, :cancelled]).order('start_time ASC').group_by { |e| e.filter_day }
            xml.venue_name venue.name
            day_events.each do |day|
              xml.day do 
                xml.day_name day[0]
                xml.events do
                  day[1].each do |event|
                    xml.event do 
                      xml.event_name event.name
                      xml.event_start_time event.date_string_start
                      xml.event_end_time event.date_string_end
                      xml.event_start_and_end_time "#{event.time_string_start} - #{event.time_string_end}"
                      xml.event_short_description event.short_description
                    end
                  end
                end
              end
            end
          end
        end
      }.to_xml
    end

    venues_xml.each do |venue_name, venue_xml_doc|
      filename = "#{DateTime.now}-festival-#{festival.id}-#{venue_name.parameterize}.xml"
      save_path = Rails.root.join('public', filename)
      File.open(save_path, 'wb') do |file|
        file << venue_xml_doc
      end
      filesnames << filename
    end

    zip_file_name = "#{DateTime.now}-festival-#{festival.id}-#{SecureRandom.hex}.zip"
    zip_file_path = Rails.root.join('public', zip_file_name)
    zip_file = File.new(zip_file_path, 'w')

    Zip::File.open(zip_file.path, Zip::File::CREATE) do |zip|
      filesnames.each do |fn|
        save_path = Rails.root.join('public', fn)
        zip.add(fn, save_path)
      end
    end

    resp = UploadService.new.upload_to_s3 "data-dumps/#{zip_file_name}", File.read(zip_file_path)

    return resp

  end


end