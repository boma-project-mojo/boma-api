require 'spec_helper'

describe AppData::Event do

  before(:all) do
    @organisation = Organisation.create! name: "Mock Org"
    @festival = Festival.new name: "Mock Festival", organisation_id: @organisation.id, timezone: "Europe/London", bundle_id: "com.com.com", schedule_modal_type: "production", start_date: DateTime.now-1.week, end_date: DateTime.now+1.week 
    @festival.remote_image_url = "https://boma-production-images.s3.amazonaws.com/test.png"
    @festival.save!

    @tag = AppData::Tag.create! name: "tag1", tag_type: "production", festival_id: @festival.id
    @venue = AppData::Venue.create! name: "venue1", venue_type: "performance", festival_id: @festival.id, remote_image_url: "https://boma-production-images.s3.amazonaws.com/test.png", description: "blah", list_order: 1
    @production = AppData::Production.create! name: "prod1", festival_id: @festival.id, description: "description", remote_image_url: "https://boma-production-images.s3.amazonaws.com/test.png"
  end

  describe "with valid params" do
    it "is valid with valid attributes" do
      @event = AppData::Event.new festival: @festival, start_time: @festival.start_date+1.day+1.hour, end_time: @festival.start_date+1.day+2.hour, venue: @venue
      @event.is_checking_app_validity = true
      @event.productions << @production
      expect(@event).to be_valid
    end

    it "is valid when two events are taking place concurrently if the venue's allow_concurrent_events attr is set to true" do
      venue = AppData::Venue.create! name: "venue1", venue_type: "performance", festival_id: @festival.id, remote_image_url: "https://boma-production-images.s3.amazonaws.com/test.png", description: "blah", allow_concurrent_events: true, list_order: 1
      @event = AppData::Event.create! festival: @festival, start_time: @festival.start_date+1.day+1.hour, end_time: @festival.start_date+1.day+2.hour, venue: venue, productions: [@production]

      @event2 = AppData::Event.new festival: @festival, start_time: @festival.start_date+1.day+1.hour, end_time: @festival.start_date+1.day+2.hour, venue: venue, productions: [@production]
      @event2.is_checking_app_validity = true
      
      expect(@event2).to be_valid
    end 
  end

  describe "with invalid params" do
    # validates :name, :presence => {message: "can't be blank"}, if: -> {is_community_event?}
    it "it is invalid without a name if a community event" do
      @event = AppData::Event.new festival: @festival, start_time: @festival.start_date+1.day+2.hour, venue: @venue, event_type: 'community_event'
      @event.valid?
      expect(@event.errors.count).to eq(1)
      expect(@event.errors['name'].to_sentence).to include("can't be blank")
    end

    # validates :start_time, :presence => {message: "can't be blank"}, if: -> {
    #   is_checking_app_validity || 
    #   publishing? || 
    #   (self.production and self.production.published?) ||
    #   is_community_event?
    # }
    it "raises a validation error if publishing without a valid start_time" do    
      @event = AppData::Event.new festival: @festival, end_time: @festival.start_date+1.day+2.hour, venue: @venue
      @event.is_checking_app_validity = true
      @event.productions << @production
      @event.valid?
      expect(@event.errors.count).to eq(1)
      expect(@event.errors['start_time'].to_sentence).to include("can't be blank")
    end 

    it "it is valid without a start_time if not publishing" do
      @event = AppData::Event.new festival: @festival, end_time: @festival.start_date+1.day+2.hour, venue: @venue
      @event.productions << @production
      expect(@event).to be_valid  
    end

    it "it is invalid without a start_time if not publishing and a community event" do
      @event = AppData::Event.new festival: @festival, name: "name", end_time: @festival.start_date+1.day+2.hour, venue: @venue, event_type: 'community_event'
      @event.valid?
      expect(@event.errors.count).to eq(1)
      expect(@event.errors['start_time'].to_sentence).to include("can't be blank")
    end

    # validates :end_time, :presence => {message: "can't be blank"}, if: -> {
    #   (
    #     is_checking_app_validity || 
    #     publishing? || 
    #     (self.production and self.production.published?) 
    #   ) &&
    #   !is_community_event?
    # }
    it "raises a validation error if publishing without a valid end_time" do
      @event = AppData::Event.new festival: @festival, start_time: @festival.start_date+1.day+2.hour, venue: @venue
      @event.is_checking_app_validity = true
      @event.productions << @production
      @event.valid?
      expect(@event.errors.count).to eq(1)
      expect(@event.errors['end_time'].to_sentence).to include("can't be blank")
    end

    it "it is valid without a end_time if not publishing" do
      @event = AppData::Event.new festival: @festival, start_time: @festival.start_date+1.day+2.hour, venue: @venue
      @event.productions << @production
      expect(@event).to be_valid  
    end

    # validate :end_time_after_start_time, unless: :is_community_event?
    it "raises a validation error if the end_time is before start_time" do
      @event = AppData::Event.new festival: @festival, start_time: @festival.start_date+1.day+2.hour, end_time: @festival.start_date+1.day+1.hour,venue: @venue
      @event.is_checking_app_validity = true
      @event.productions << @production
      @event.valid?
      expect(@event.errors.count).to eq(1)
      expect(@event.errors['end_time'].to_sentence).to include("must be after start time")
    end

    # validate :has_valid_productions, if: -> {
    #   (
    #     (is_checking_app_validity and !checking_production_validity) || 
    #     publishing?
    #   ) &&
    #   requires_production?
    # }
    it "fails to publish an AppData::Event without a valid production" do
      @event = AppData::Event.new festival: @festival, start_time: @festival.start_date+1.day+2.hour, end_time: @festival.start_date+1.day+4.hour, venue: @venue
      @event.is_checking_app_validity = true
      @event.valid?
      expect(@event.errors.count).to eq(2)
      expect(@event.errors['productions'].to_sentence).to include("can't be blank and at least one.")  
    end

    it "it is valid without a production if a community event" do
      @event = AppData::Event.new festival: @festival, name: "name", start_time: @festival.start_date+1.day+2.hour, venue: @venue, event_type: 'community_event'
      @event.valid?
      expect(@event).to be_valid 
    end
    
    # validates :venue, :presence => {message: "can't be blank"}, unless: -> {is_virtual_event?}
    it "raises a validation error if the venue isn't set" do
      @event = AppData::Event.new festival: @festival, start_time: @festival.start_date+1.day+2.hour, end_time: @festival.start_date+1.day+4.hour
      @event.is_checking_app_validity = true
      @event.productions << @production
      @event.valid?
      expect(@event.errors.count).to eq(1)
      expect(@event.errors['venue'].to_sentence).to include("can't be blank")
    end

    # validates :festival_id, :presence => {message: "can't be blank"}
    it "raises a validation error if the festival isn't set" do
      @event = AppData::Event.new start_time: @festival.start_date+1.day+2.hour, end_time: @festival.start_date+1.day+4.hour, venue: @venue
      @event.is_checking_app_validity = true
      @event.productions << @production
      @event.valid?
      expect(@event.errors.count).to eq(2)
      expect(@event.errors['festival_id'].to_sentence).to include("can't be blank")    
      expect(@event.errors['festival'].to_sentence).to include("must exist")    
    end

    # validate :clashing_events
    it "raises a validation error if the events clash isn't set" do
      @event = AppData::Event.create! festival: @festival, start_time: @festival.start_date+1.day+1.hour, end_time: @festival.start_date+1.day+2.hour, venue: @venue, productions: [@production]
      @event2 = AppData::Event.new festival: @festival, start_time: @festival.start_date+1.day+1.hour+10.minutes, end_time: @festival.start_date+1.day+2.hour, venue: @venue, productions: [@production]
      @event2.is_checking_app_validity = true
      @event2.valid?
      expect(@event2.errors.count).to eq(1)
      error = " - Event clash!  Only one event can take place at each venue at a time.  The event you're trying to create clashes with #{@production.name} (#{@event.date_string_start} - #{@event.date_string_end})"
      expect(@event2.errors['start_time'].to_sentence).to include(error)   
    end 
  end

  # validates :productions, :presence => {message: "can't be blank"}
  it "raises a validation error if there is no production when creating an event" do
    @event = AppData::Event.new festival: @festival, start_time: @festival.start_date+1.day+2.hour, end_time: @festival.start_date+1.day+4.hour, venue: @venue
    @event.valid?
    expect(@event.errors.count).to eq(1)
    expect(@event.errors['productions'].to_sentence).to include("can't be blank")    
  end

  describe "clashfinder positioning params are correctly calculated" do
    it "start_position returns an integer represetning the number of minutes between clashfinder_start_hour and the start of the event" do
      @festival.clashfinder_start_hour = 3
      @festival.save!

      @event = AppData::Event.create! festival: @festival, start_time: DateTime.new(2025, 12, 1, 11, 00), end_time: DateTime.new(2025, 12, 1, 13, 00), venue: @venue, productions: [@production]
    
      # 11:00 - 3 hours (becuase clashfinder_start_hour === 3) * 60
      expect(@event.start_position).to eq(480.0)
    end

    it "end_position returns an integer represetning the number of minutes between clashfinder_start_hour and the end of the event" do
      @festival.clashfinder_start_hour = 3
      @festival.save!

      @event = AppData::Event.create! festival: @festival, start_time: DateTime.new(2025, 12, 1, 11, 00), end_time: DateTime.new(2025, 12, 1, 13, 00), venue: @venue, productions: [@production]
       
      # 13:00 - 3 hours (becuase clashfinder_start_hour === 3) * 60
      expect(@event.end_position).to eq(600)
    end
    
    it "event_duration_in_mins returns an integer representing the duration of the event in minutes" do
      @event = AppData::Event.create! festival: @festival, start_time: DateTime.new(2025, 12, 1, 11, 00), end_time: DateTime.new(2025, 12, 1, 13, 00), venue: @venue, productions: [@production]
       
      # 13:00 - 3 hours (becuase clashfinder_start_hour === 3) * 60
      expect(@event.event_duration_in_mins).to eq(120)
    end

    it "for an event that starts at 11am the filter_day returns a string representing the actual day the event takes place" do
      @festival.clashfinder_start_hour = 3
      @festival.save!

      @event = AppData::Event.create! festival: @festival, start_time: DateTime.new(2025, 12, 1, 11, 00), end_time: DateTime.new(2025, 12, 1, 13, 00), venue: @venue, productions: [@production]

      expect(@event.filter_day).to eq("1201")
    end

    it "if festival.clashfinder_start_hour === '0' then day_start is always the same as the event" do
      @festival.clashfinder_start_hour = 0
      @festival.save!

      @event = AppData::Event.create! festival: @festival, start_time: DateTime.new(2025, 12, 1, 1, 00), end_time: DateTime.new(2025, 12, 1, 5, 00), venue: @venue, productions: [@production]
      expect(@event.day_start.to_datetime).to eq(DateTime.new(2025, 12, 1, 5, 00).to_date)

      @event = AppData::Event.create! festival: @festival, start_time: DateTime.new(2025, 12, 1, 11, 00), end_time: DateTime.new(2025, 12, 1, 13, 00), venue: @venue, productions: [@production]
      expect(@event.day_start.to_datetime).to eq(DateTime.new(2025, 12, 1, 5, 00).to_date)
    end

    it "for an early morning event which starts after the festival.clashfinder_start_hour day_start returns a string representing the actual day the event takes place" do
      @festival.clashfinder_start_hour = 3
      @festival.save!

      @event = AppData::Event.create! festival: @festival, start_time: DateTime.new(2025, 12, 1, 5, 00), end_time: DateTime.new(2025, 12, 1, 7, 00), venue: @venue, productions: [@production]
      expect(@event.day_start.to_datetime).to eq(DateTime.new(2025, 12, 1, 3, 00))
    end

    it "for an early morning event which starts before the festival.clashfinder_start_hour day_start returns a string representing the day before the event takes place" do
      @festival.clashfinder_start_hour = 3
      @festival.save!

      @event = AppData::Event.create! festival: @festival, start_time: DateTime.new(2025, 12, 1, 1, 00), end_time: DateTime.new(2025, 12, 1, 3, 00), venue: @venue, productions: [@production]
      expect(@event.day_start.to_datetime).to eq(DateTime.new(2025, 11, 30, 3, 00))  
    end

    it "start_hour returns returns an integer representing the hours an event starts" do
      @event = AppData::Event.create! festival: @festival, start_time: DateTime.new(2025, 12, 1, 23, 00), end_time: DateTime.new(2025, 12, 1, 23, 40), venue: @venue, productions: [@production]
      expect(@event.start_hour
      ).to eq(23)    
    end
    
    it "start_day returns an integer representing the day of the month the event starts" do
      @event = AppData::Event.create! festival: @festival, start_time: DateTime.new(2025, 4, 19, 22, 00), end_time: DateTime.new(2025, 4, 19, 23, 40), venue: @venue, productions: [@production]
      expect(@event.start_day).to eq(19)
    end

    it "end_day returns an integer representing the day of the month the event ends" do
      @event = AppData::Event.create! festival: @festival, start_time: DateTime.new(2025, 4, 19, 3, 00), end_time: DateTime.new(2025, 4, 19, 4, 40), venue: @venue, productions: [@production]
      expect(@event.end_day).to eq(19)    
    end

    it "start_day and end_day are not effected by festival.clashfinder_start_hour" do
      @festival.clashfinder_start_hour = 3
      @festival.save!

      @event = AppData::Event.create! festival: @festival, start_time: DateTime.new(2025, 12, 1, 2, 00), end_time: DateTime.new(2025, 12, 1, 2, 30), venue: @venue, productions: [@production]
      expect(@event.start_day).to eq(1)  

      @event = AppData::Event.create! festival: @festival, start_time: DateTime.new(2025, 12, 1, 4, 00), end_time: DateTime.new(2025, 12, 1, 5, 30), venue: @venue, productions: [@production]
      expect(@event.start_day).to eq(1)  
    end

    it "end_hour returns an integer representing the hours an event ends" do
      @event = AppData::Event.create! festival: @festival, start_time: DateTime.new(2025, 4, 19, 3, 00).in_time_zone(@festival.timezone), end_time: DateTime.new(2025, 4, 19, 4, 40), venue: @venue, productions: [@production]
      expect(@event.end_hour).to eq(5)
    end

    it "end_minutes returns an integer representing the minutes past the hour an event ends" do
      @event = AppData::Event.create! festival: @festival, start_time: DateTime.new(2025, 4, 19, 2, 00), end_time: DateTime.new(2025, 4, 19, 3, 25), venue: @venue, productions: [@production]
      expect(@event.end_mins).to eq(25)
    end

    it "the couchdb record includes all neccessary attributes for clashfinder in the correct format" do
      @festival.clashfinder_start_hour = 3
      @festival.save!
      
      @event = AppData::Event.create! festival: @festival, start_time: DateTime.new(2025, 4, 19, 3, 00).in_time_zone(@festival.timezone), end_time: DateTime.new(2025, 4, 19, 4, 40), venue: @venue, productions: [@production]
      
      couchdb_record = @event.to_couch_data

      # start_position
      expect(couchdb_record[:start_position]).to eq(60.0)
      expect(couchdb_record[:start_position]).to be_a_kind_of(Float) 
      # end_position
      expect(couchdb_record[:end_position]).to eq(160.0)
      expect(couchdb_record[:end_position]).to be_a_kind_of(Float) 
      # event_duration_in_mins
      expect(couchdb_record[:event_duration_in_mins]).to eq(100.0)
      expect(couchdb_record[:event_duration_in_mins]).to be_a_kind_of(Float) 
      # filter_day
      expect(couchdb_record[:filter_day]).to eq("0419")
      expect(couchdb_record[:filter_day]).to be_a_kind_of(String) 
      # start_hour
      expect(couchdb_record[:start_hour]).to eq(4)
      expect(couchdb_record[:start_hour]).to be_a_kind_of(Integer)
      # start_day
      expect(couchdb_record[:start_day]).to eq(19)
      expect(couchdb_record[:start_day]).to be_a_kind_of(Integer)
      # end_day
      expect(couchdb_record[:end_day]).to eq(19)
      expect(couchdb_record[:end_day]).to be_a_kind_of(Integer)
      # end_hours
      expect(couchdb_record[:end_hour]).to eq(5)
      expect(couchdb_record[:end_hour]).to be_a_kind_of(Integer)
      # end_mins
      expect(couchdb_record[:end_mins]).to eq(40)
      expect(couchdb_record[:end_mins]).to be_a_kind_of(Integer)
    end
  end
end