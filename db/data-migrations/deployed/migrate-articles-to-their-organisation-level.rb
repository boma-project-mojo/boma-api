Festival.all.each do |festival|
	puts "Migrating articles for #{festival.name}"
	festival.articles.each do |article|
		next if article.organisation_id === festival.organisation.id
		puts "Migrating article #{article.id}"
		article.update! organisation_id: festival.organisation.id
	end
end