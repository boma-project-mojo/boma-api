Festival.where(analysis_enabled: true).each do |festival|
	# Rollup into hourly stats
	first_stats_cache = StatsCache.where(festival_id: festival.id)
																.where(period_length: "10m")
																.order('created_at ASC')
																.limit(1)
																.first

	last_stats_cache = StatsCache.where(festival_id: festival.id)
																.where(period_length: "10m")
																.order('created_at DESC')
																.limit(1)
																.first

	first_stats_cache_hour = first_stats_cache.created_at.beginning_of_hour.to_time
	last_stats_cache_hour = last_stats_cache.created_at.end_of_hour.to_time

	total_hours_to_calculate = (last_stats_cache_hour - first_stats_cache_hour) / 1.hours

	puts "\nProcessing #{total_hours_to_calculate} hours for festival #{festival.name}\n"

	(0...total_hours_to_calculate).each_with_index do |hour_counter, i|
		print "\r#{i+1}/#{total_hours_to_calculate}"
		StatsCacheService.rollup_stats festival.id, 'hour', first_stats_cache.created_at + hour_counter.hours
	end

	# Rollup into daily stats

	first_stats_cache = StatsCache.where(festival_id: festival.id)
																.where(period_length: "1h")
																.order('created_at ASC')
																.limit(1)
																.first

	last_stats_cache = StatsCache.where(festival_id: festival.id)
																.where(period_length: "1h")
																.order('created_at DESC')
																.limit(1)
																.first

	first_stats_cache_day = first_stats_cache.created_at.beginning_of_day.to_time
	last_stats_cache_day = last_stats_cache.created_at.end_of_day.to_time

	total_days_to_calculate = (last_stats_cache_day - first_stats_cache_day) / 1.days

	puts "\nProcessing #{total_days_to_calculate} days for festival #{festival.name}\n"

	(0...total_days_to_calculate).each_with_index do |day_counter, i|
		print "\r#{i+1}/#{total_days_to_calculate}"
		StatsCacheService.rollup_stats festival.id, 'day', first_stats_cache.created_at + day_counter.days
	end
end