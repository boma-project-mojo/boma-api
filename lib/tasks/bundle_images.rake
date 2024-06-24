namespace :bundle do
  desc "Cache images from json file"
  task :images, [:festival_id] => :environment do |t, args|
    raise "You must specify the festival_id as an argument for this rake task in the format rake bundle:images[FESTIVAL_ID]" if args[:festival_id].blank?

    STDOUT.sync = true
    count = AppData::Production.where(festival_id: args[:festival_id]).published.count
    puts "bundling #{count} production images"
    AppData::Production.where(festival_id: args[:festival_id]).published.each_with_index do |p,i|
      print "\rbundling #{i+1}/#{count}"
      p.bundle_image
    end
    print "\n"

    count = AppData::Venue.where.not(venue_type: "community_venue").where(festival_id: args[:festival_id]).published.count
    puts "bundling #{count} venue images"
    count = AppData::Venue.where.not(venue_type: "community_venue").where(festival_id: args[:festival_id]).published.count
    AppData::Venue.where.not(venue_type: "community_venue").where(festival_id: args[:festival_id]).published.each_with_index do |v,i|
      print "\rbundling #{i+1}/#{count}"
      v.bundle_image
    end 
    print "\n"

    count = AppData::Page.where(festival_id: args[:festival_id]).published.count
    puts "bundling #{count} page images"      
    AppData::Page.where(festival_id: args[:festival_id]).published.each_with_index do |p,i|
      print "\rbundling #{i+1}/#{count}"
      p.bundle_image
    end 
    print "\n"

    count = AppData::Article.boma_articles.where(festival_id: args[:festival_id]).published.count
    puts "bundling #{count} page images"      
    AppData::Article.boma_articles.where(festival_id: args[:festival_id]).published.each_with_index do |article,i|
      print "\rbundling #{i+1}/#{count}"
      article.bundle_image
    end 
    print "\n"
  end
end