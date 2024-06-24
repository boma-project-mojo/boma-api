Festival.all.each do |festival|
	festival.events.each do |event|
		event.calculate_preload
		begin
			event.save!
		rescue Exception => e
			puts e
		end
	end

	festival.productions.each do |production|
		production.calculate_preload
		begin
			production.save!
		rescue Exception => e
			puts e
		end
	end
end