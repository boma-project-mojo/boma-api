AppData::Article.all.each {|a| 
a.image.recreate_versions!(:loader)
puts "recreated image for article-id #{a.id}"
}
AppData::Event.community_events.published.each {|a| 
a.image.recreate_versions!(:loader)
puts "recreated image for event-id #{a.id}"
}
AppData::Page.all.published.each {|a| 
a.image.recreate_versions!(:loader)
puts "recreated image for page-id #{a.id}"
}