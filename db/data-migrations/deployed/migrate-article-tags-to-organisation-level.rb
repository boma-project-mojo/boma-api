AppData::Tag.where(tag_type: [:article, :community_article]).each do |tag|
	if tag.festival
		puts "Migrating #{tag.name}"
		tag.update! organisation_id: tag.festival.organisation.id, festival_id: nil
	end
end