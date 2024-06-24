namespace :bundle do
  desc "Cache images from json file"
  task :touch, [:festival_id] => :environment do |t, args|

    raise "You must specify the festival_id as an argument for this rake task in the format rake bundle:touch[FESTIVAL_ID]" if args[:festival_id].blank?

    STDOUT.sync = true
    count = AppData::Production.where(festival_id: args[:festival_id]).published.count
    puts "touching #{count} production images"
    AppData::Production.where(festival_id: args[:festival_id]).published.each_with_index do |p,i|
      print "\rbundling #{i+1}/#{count}"
      if p.image_bundled_at.nil? or p.image_bundled_at < p.image_last_updated_at
        puts "touching"
        p.touch_image_bundled_at!
      end
    end
    print "\n"

    count = AppData::Venue.where.not(venue_type: "community_venue").where(festival_id: args[:festival_id]).published.count
    puts "touching #{count} venue images"
    count = AppData::Venue.where.not(venue_type: "community_venue").where(festival_id: args[:festival_id]).published.count
    AppData::Venue.where.not(venue_type: "community_venue").where(festival_id: args[:festival_id]).published.each_with_index do |v,i|
      print "\rbundling #{i+1}/#{count}"
      if v.image_bundled_at.nil? or v.image_bundled_at < v.image_last_updated_at
        puts "touching"
        v.touch_image_bundled_at!
      end
    end
    print "\n"

    count = AppData::Page.where(festival_id: args[:festival_id]).published.count
    puts "touching #{count} page images"      
    AppData::Page.where(festival_id: args[:festival_id]).published.each_with_index do |p,i|
      print "\rbundling #{i+1}/#{count}"
      if p.image_bundled_at.nil? or p.image_bundled_at < p.image_last_updated_at
        puts "touching"
        p.touch_image_bundled_at!
      end
    end 
    print "\n"

    count = AppData::Article.boma_articles.where(festival_id: args[:festival_id]).published.count
    puts "touching #{count} articles images"      
    AppData::Article.boma_articles.where(festival_id: args[:festival_id]).published.each_with_index do |p,i|
      print "\rbundling #{i+1}/#{count}"
      if p.image_bundled_at.nil? or p.image_bundled_at < p.image_last_updated_at
        puts "touching"
        p.touch_image_bundled_at!
      end
    end 
    print "\n"
  end
end