# This rake task creates couchdb records for a festival.  
#
# It is useful when keeping a local or staging couchdb up to date with production
# when you don't want to import a copy of the production database.  
namespace :couchdb do
  desc "Cache images from json file"
  task :bootstrap, [:festival_id] => :environment do |t, args|
    STDOUT.sync = true

    # # events over next weekend - WARNING! WRITES TO DB!!!
    # count = AppData::Event.published.count 
    # puts "setting time for #{count} event records"
    # AppData::Event.published.order('start_time ASC').each_with_index do |e,i|
    #  print "\r#{i+1}/#{count}"
    #   new_start_time = Date.current.next_week(Date::DAYNAMES[e.start_time.wday].downcase.to_sym).to_datetime.change({ hour: e.start_time.hour, min: e.start_time.min }) rescue nil
    #   new_end_time = Date.current.next_week(Date::DAYNAMES[e.end_time.wday].downcase.to_sym).to_datetime.change({ hour: e.end_time.hour, min: e.end_time.min }) rescue nil

    #   e.update! start_time: new_start_time, end_time: new_end_time
    # end
    # print "\n"      

    # events over next x minutes - WARNING! WRITES TO DB!!!
    # count = AppData::Event.published.count
    # puts "setting time for #{count} event records"
    # AppData::Event.published.order('start_time ASC').each_with_index do |e,i|
    #   print "\r#{i+1}/#{count}"
    #   e.update! start_time: (DateTime.now + i.minutes), end_time: (DateTime.now + (i+10).minutes) 
    # end
    # print "\n"

    @festival = Festival.find(args[:festival_id])

    puts "bundling festival record"     
    @festival.couch_update_or_create
    @festival.create_couchdb_design_docs

    puts "bundling festival token_types"  
    begin
      @festival.organisation.token_types.each do |tt|
        tt.couch_update_or_create_all_festivals
      end
    rescue
      puts "Festival hasn't got an organisiation"
    end

    count = @festival.events.published.count
    puts "bundling #{count} event records"      
    @festival.events.published.each_with_index do |e,i|
      print "\r#{i+1}/#{count}"
      if e.valid_for_app?
        e.couch_update_or_create
      else
        print "\n"
        e.errors.messages.each{|m| puts m }
      end
    end
    print "\n"          

    count = @festival.venues.published.count
    puts "bundling #{count} venue records"      
    @festival.venues.published.each_with_index do |v,i|
      print "\r#{i+1}/#{count}"
      if v.valid_for_app?
        v.couch_update_or_create
      else
        print "\n"          
        v.errors.messages.each{|m| puts m }
      end
    end
    print "\n"          

    count = @festival.productions.published.count
    puts "bundling #{count} production records"      
    @festival.productions.published.each_with_index do |p,i|
      print "\r#{i+1}/#{count}"
      if p.valid_for_app?
        p.couch_update_or_create
      else
        print "\n"          
        p.errors.messages.each{|m| puts m }
      end
    end
    print "\n"  

    count = @festival.tags.published.count
    puts "bundling #{count} tag records"      
    @festival.tags.published.each_with_index do |t,i|
      print "\r#{i+1}/#{count}"
      t.couch_update_or_create
    end
    print "\n"          

    count = @festival.pages.published.count
    puts "bundling #{count} page records"      
    @festival.pages.published.each_with_index do |p,i|
      print "\r#{i+1}/#{count}"
      p.couch_update_or_create
    end
    print "\n"   

    if @festival.people
      count = @festival.people.published.count
      puts "bundling #{count} people records"      
      @festival.people.published.each_with_index do |p,i|
        print "\r#{i+1}/#{count}"
        p.couch_update_or_create
      end
      print "\n"    
    end  

    count = @festival.articles.published.count
    puts "bundling #{count} article records" 
    @festival.articles.published.each_with_index do |article,i|
      print "\r#{i+1}/#{count}"
      article.couch_update_or_create
    end
    print "\n"        
  end
end