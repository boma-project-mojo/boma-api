namespace :stats do
  task cache: :environment do
  	StatsCacheService.cache_stats
  end

  task create_hourly_stats: :environment do
	  Festival.where(analysis_enabled: true).each do |festival|
			StatsCacheService.rollup_stats festival.id, 'hour'
	  end
	end

	task create_daily_stats: :environment do
	  Festival.where(analysis_enabled: true).each do |festival|
	  	StatsCacheService.rollup_stats festival.id, 'day'
	  end
	end
end