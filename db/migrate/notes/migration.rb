AppData::Venue.find(24074).events.each{|e| e.update!(aasm_state: :draft); e.production.update!(aasm_state: :locked); e.production.update!(aasm_state: :draft)  }
AppData::Venue.find(212).events.each{|e| e.update!(aasm_state: :draft); e.production.update!(aasm_state: :locked); e.production.update!(aasm_state: :draft)  }



results = User.all.map{|u| [u.email, AppData::Event.where(created_by:u.id).count, AppData::Event.where(created_by: u.id, aasm_state: :published).count] }
results.sort{|x,y| y[1] <=> x[1] }.each{|r| puts r[0]+": "+r[1].to_s+" ("+r[2].to_s+")"}