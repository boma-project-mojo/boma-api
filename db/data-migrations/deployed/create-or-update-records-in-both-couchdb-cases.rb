@festival = Festival.find(3)

@festival.articles.published.each_with_index do |article,i|
	article.couch_update_or_create
	puts "updated couch db for article id#{article.id}"
end

@festival.events.community_events.published.each_with_index do |event,i|
	event.couch_update_or_create
	puts "updated couch db for event id#{event.id}"
end

@festival.pages.published.each_with_index do |page,i|
	page.couch_update_or_create
	puts "updated couch db for page id#{page.id}"
end