# STATS CACHE SERVICE

# This service aggregates and stores a cache of the total activity that has been reported over 
# a configurable time period ready for the StatsDisplayService to display for the admin CMS.  
#
# For each time period and Festival a StatsCache record is created which includes a JSON object 
# detailing the total for this period and the cumulative total for each stat_type.  
# 
# The cache is generated using the following rake task which is run by the heroku scheduler.  
#
# `rake stats:cache``
#
# Additionally stats are rolled up to create an hourly and daily period which is used to display stats
# for a longer time period.  
#
# `rake stats:create_hourly_stats`
# `rake stats:create_daily_stats`

class StatsCacheService
	attr :now, :period_data

	# the function for the cron 
	# now 			now (DateTime)
	def self.cache_stats now=DateTime.now.beginning_of_minute
		@now = now

		Festival.where(analysis_enabled: true).each do |festival|
			self.cache_stats_for_festival festival.id, @now
		end
	end

	# cache_state for a festival
	# festival_id  		id of Festival (int)
	# now  						DateTime
	def self.cache_stats_for_festival festival_id, now
		@period_data = []

		@festival = Festival.find(festival_id)

		@previous_period = StatsCache.where(festival_id: festival_id).limit(1).order('id desc')

		activity = self.get_activity festival_id

		puts "Festival #{festival_id} has #{activity.count} app_usage activity records"

		notifications_in_last_ten_mins = self.push_notifications_in_last_ten_mins festival_id, now
		notifications_all_time = self.push_notifications_all_time festival_id

		new_content = self.new_content_published_in_last_ten_mins festival_id, now
		org_addresses = self.organisation_addresses_in_last_ten_mins festival_id, now

		view_models = []
		love_models = []

		if(@festival.articles.published.count > 0)
			view_models << 'article'
			love_models << 'article'
		end

		if(@festival.schedule_modal_type)
			view_models << @festival.schedule_modal_type
		end

		if(@festival.events.count > 0)
			love_models << 'event'
		end

		self.love_by_model love_models, activity, festival_id
		self.views_by_model view_models, activity, festival_id

		self.love_by_model_by_tag love_models, activity, festival_id
		self.views_by_model_by_tag view_models, activity, festival_id

		self.love_by_model_by_type love_models, activity, festival_id
		self.views_by_model_by_type view_models, activity, festival_id

		self.app_pings activity, festival_id

		self.app_notifications notifications_in_last_ten_mins, notifications_all_time, festival_id

		self.new_content_published new_content, festival_id
		
		self.new_users_joined org_addresses, festival_id
    self.app_versions org_addresses, festival_id

		# Persist the Data
		self.store_stat festival_id, "10m"
	end

  # Return the reported data as a JSON hash
  # Implemented in 1a3f1e4f8c35af3078c08d3fbf690c2ebb3cbff9 to resolve a bug
  def self.get_reported_data activity
    activity.reported_data.is_a?(Hash) ? activity.reported_data : JSON.parse(activity.reported_data)
  end

	# Get activity for all wallets
	# festival_id 	Id of Festival (int)
	def self.get_activity festival_id
		Activity.where(festival_id: festival_id).where(activity_type: :app_usage).uniq {|a| a.address_id}
	end

  # Calculate the period total using the previous periods state and the latest cumulative total
  # stat_type           string    the identifier for this stat type
  # cumulative_total    int       the cumulative total for the period currently being cached.  
	def self.calculate_period_total_for_stat_type stat_type, cumulative_total
		# Handle the case where there is no previous period for this stat_type
    # e.g the first stats for a new festival
    if @previous_period.count > 0
			stat_type_previous_period = @previous_period[0].period_data.select { |st| st['stat_type'] === stat_type }

      # Handle the case where the previous period doesn't have an instance of this stat_type 
      # e.g a new tag
			if(stat_type_previous_period.length === 0)
				previous_period_cumulative_total = 0
			else
				previous_period_cumulative_total = stat_type_previous_period[0]["cumulative_total"]
			end

			period_total = cumulative_total - previous_period_cumulative_total
		else
			period_total = cumulative_total
		end

		return period_total
	end

	# Get push notifications sent in last ten minutes
	# festival_id 	id of Festival (int)
	# now   				time now (DateTime object)
	def self.push_notifications_in_last_ten_mins festival_id, now=DateTime.now.beginning_of_minute
		PushNotification.where(festival_id: festival_id).where('created_at > ?', now-10.minutes).where('created_at < ?', now)
	end

	# Get push notifications sent in total
	# festival_id 	id of Festival (int)
	# now   				time now (DateTime object)
	def self.push_notifications_all_time festival_id
		PushNotification.where(festival_id: festival_id)
	end

	# Get organisation_addresses created in last ten minutes
	# festival_id 	id of Festival (int)
	# now   				time now (DateTime object)
	def self.organisation_addresses_in_last_ten_mins festival_id, now=DateTime.now.beginning_of_minute
		Festival.find(festival_id).organisation.organisation_addresses.where('created_at > ?', now-10.minutes).where('created_at < ?', now)
	end

	# Get events and articles published in the last ten minutes
	# festival_id 	id of Festival (int)
	# now   				time now (DateTime object)
	def self.new_content_published_in_last_ten_mins festival_id, now=DateTime.now.beginning_of_minute
    # Get all new events created in the last ten minutes
		new_events = AppData::Event.where(festival_id: festival_id).where('published_at > ?', now-10.minutes).where('published_at < ?', now)
		# Get all new articles created in the last ten minutes
    new_articles = AppData::Article.where(festival_id: festival_id).where('published_at > ?', now-10.minutes).where('published_at < ?', now)
	
		return {
			events: new_events,
			articles: new_articles
		}
	end

	# calulate and store the StatsCache for love for all reported models (e.g event)
	# models   				Array of model names (array)
	# activity 				Activity records (ActiveRecord array)
	# festival_id  		id of Festival (int)
	def self.love_by_model models, activity, festival_id
		models.each do |model|
			stat_type = "love_by_#{model}"

			cumulative_total = activity.sum{|a| 
        begin
          self.get_reported_data(a)["love"][model]["total"]
        rescue NoMethodError => e
          0
        end
      }

			period_total = self.calculate_period_total_for_stat_type stat_type, cumulative_total
			
			self.create_period_data_object(stat_type, festival_id, cumulative_total, period_total)
		end
	end

	# calulate and store the StatsCache for view for all reported models (e.g 'event')
	# models   				Array of model names (array)
	# activity 				Activity records (ActiveRecord array)
	# festival_id  		id of Festival (int)
	def self.views_by_model models, activity, festival_id
		models.each do |model|
			stat_type = "views_by_#{model}"

			cumulative_total = activity.sum{|a| 
        begin
          self.get_reported_data(a)["view"][model]["total"]
        rescue NoMethodError => e
          0
        end
      }
      
			period_total = self.calculate_period_total_for_stat_type stat_type, cumulative_total

			self.create_period_data_object(stat_type, festival_id, cumulative_total, period_total)
		end
	end

	# calulate and store the StatsCache for love for tags for all reported models (e.g event)
	# models   				Array of model names (array)
	# activity 				Activity records (ActiveRecord array)
	# festival_id  		id of Festival (int)
	def self.love_by_model_by_tag models, activity, festival_id
		models.each do |model|
			tags = activity.collect{|a| self.get_reported_data(a)["love"][model]['tags'].keys rescue nil}.flatten.compact.uniq

			tags.each do |tag_id|
				begin
					tag = @festival.tags.find(tag_id)
					stat_type = "love_by_#{model}_by_tag_#{tag_id}"

          cumulative_total = activity.collect{|a| 
            begin
              self.get_reported_data(a)["love"][model]["tags"][tag_id]
            rescue NoMethodError => e
              0
            end
          }.compact.sum

					period_total = self.calculate_period_total_for_stat_type stat_type, cumulative_total

					self.create_period_data_object(stat_type, festival_id, cumulative_total, period_total, {name: "Love for #{tag.name} (#{model})"})
				rescue Exception => e
          # There is a known issue where, presumably during testing some activity was created for tags which don't belong to this festival.  
          # we can safely ignore these and they have no impact.  
          puts e
				end
			end
		end
	end

	# calulate and store the StatsCache views for tags for all reported models (e.g event)
	# models   				Array of model names (array)
	# activity 				Activity records (ActiveRecord array)
	# festival_id  		id of Festival (int)
	def self.views_by_model_by_tag models, activity, festival_id
		models.each do |model|
			tags = activity.collect{|a| self.get_reported_data(a)["view"][model]['tags'].keys rescue nil}.flatten.compact.uniq

			tags.each do |tag_id|
				begin
					tag = @festival.tags.find(tag_id)

					stat_type = "views_by_#{model}_by_tag_#{tag_id}"
	
          cumulative_total = activity.collect{|a| 
            begin
              self.get_reported_data(a)["view"][model]["tags"][tag_id]
            rescue NoMethodError => e
              0
            end
          }.compact.sum

					period_total = self.calculate_period_total_for_stat_type stat_type, cumulative_total

					self.create_period_data_object(stat_type, festival_id, cumulative_total, period_total, {name: "Views for #{tag.name} (#{model})"})
				rescue Exception => e
          # There is a known issue where, presumably during testing some activity was created for tags which don't belong to this festival.  
          # we can safely ignore these and they have no impact.  
          puts e
				end
			end
		end
	end

	# calulate and store the StatsCache love by model_type for reported models (e.g event)
	# models   				Array of model names (array)
	# activity 				Activity records (ActiveRecord array)
	# festival_id  		id of Festival (int)
	def self.love_by_model_by_type models, activity, festival_id
		models.each do |model|
			model_types = activity.collect{|a| self.get_reported_data(a)["love"][model]["#{model}_type"].keys rescue nil}.flatten.compact.uniq

			model_types.each do |model_type|
				stat_type = "love_by_#{model}_type_by_#{model_type}"

        cumulative_total = activity.collect{|a| 
          begin
            self.get_reported_data(a)["love"][model]["#{model}_type"][model_type]
          rescue NoMethodError => e
            0
          end
        }.compact.sum

				period_total = self.calculate_period_total_for_stat_type stat_type, cumulative_total
				
				# There was some confusion about what a boma_event or boma_article was, this clears this up 
				model_type = "Festival Events" if(model_type === 'boma_event')
				model_type = "Festival Articles" if(model_type === 'boma_article')
				model_type = "Festival Audio" if(model_type === 'boma_audio_article')
				model_type = "Festival News" if(model_type === 'boma_news_article')	

				self.create_period_data_object(stat_type, festival_id, cumulative_total, period_total, {name: "Love for #{model_type}s"})
			end
		end
	end

	# calulate and store the StatsCache views by model_type for reported models (e.g event)
	# models   				Array of model names (array)
	# activity 				Activity records (ActiveRecord array)
	# festival_id  		id of Festival (int)
	def self.views_by_model_by_type models, activity, festival_id
		models.each do |model|
			model_types = activity.collect{|a| self.get_reported_data(a)["view"][model]["#{model}_type"].keys rescue nil}.flatten.compact.uniq

			model_types.each do |model_type|
				stat_type = "views_by_#{model}_type_by_#{model_type}"

        cumulative_total = activity.collect{|a| 
          begin
            self.get_reported_data(a)["view"][model]["#{model}_type"][model_type]
          rescue NoMethodError => e
            0
          end
        }.compact.sum

				period_total = self.calculate_period_total_for_stat_type stat_type, cumulative_total

				# There was some confusion about what a boma_event or boma_article was, this clears this up 
				model_type = "Festival Events" if(model_type === 'boma_event')
				model_type = "Festival Articles" if(model_type === 'boma_article')
				model_type = "Festival Audio" if(model_type === 'boma_audio_article')			
				model_type = "Festival News" if(model_type === 'boma_news_article')				

				self.create_period_data_object(stat_type, festival_id, cumulative_total, period_total, {name: "Views for #{model_type}s"})
			end
		end		
	end

	# calulate and store the StatsCache for app pings
	# activity 				Activity records (ActiveRecord array)
	# festival_id  		id of Festival (int)
	def self.app_pings activity, festival_id
		stat_type = "app_pings"

		cumulative_total = activity.sum{|a| 
      begin
        self.get_reported_data(a)["ping"]["total_all"].to_i 
      rescue NoMethodError => e
        0
      end
    }
		
		period_total = self.calculate_period_total_for_stat_type stat_type, cumulative_total

		self.create_period_data_object(stat_type, festival_id, cumulative_total, period_total)
	end

	# calulate and store the StatsCache for notifications
	# activity 				Activity records (ActiveRecord array)
	# festival_id  		id of Festival (int)
	def self.app_notifications activity, all_time, festival_id
		stat_type = "app_notifications"
		period_total = activity.count
		cumulative_total = all_time.count

		self.create_period_data_object(stat_type, festival_id, cumulative_total, period_total)
	end

	# calulate and store the StatsCache for new_content_published
	# activity 				Activity records (ActiveRecord array)
	# festival_id  		id of Festival (int)
	def self.new_content_published activity, festival_id
		stat_type = "new_content_published"
		period_total = activity[:articles].count + activity[:events].count
		meta = {
			articles: {
				total: activity[:articles].count,
				by_article_type: activity[:articles].group(:article_type).count,
				published_content: JSON.parse(activity[:articles].to_json)
			},
			events: {
				total_new: activity[:events].count,
				by_event_type: activity[:events].group(:event_type).count,
				published_content: JSON.parse(activity[:events].to_json)
			}
		}

		self.create_period_data_object(stat_type, festival_id, nil, period_total, meta)
	end

	# calulate and store the StatsCache for new_users
	# activity 				Activity records (ActiveRecord array)
	# festival_id  		id of Festival (int)
	def self.new_users_joined organisation_addresses, festival_id
		stat_type = "new_users"
		period_total = organisation_addresses.count
		cumulative_total = Festival.find(festival_id).organisation.organisation_addresses.count

		self.create_period_data_object(stat_type, festival_id, cumulative_total, period_total)
	end

	# calulate and store the StatsCache for app_versions
	# activity 				Activity records (ActiveRecord array)
	# festival_id  		id of Festival (int)
	def self.app_versions organisation_addresses, festival_id
    organisation = Festival.find(festival_id).organisation
    app_versions = organisation.organisation_addresses.select(:app_version).distinct

    app_versions.each do |av|
      stat_type = "app_versions_#{av.app_version}"
      period_total = organisation_addresses.where(app_version: av.app_version).count
      cumulative_total = organisation.organisation_addresses.where(app_version: av.app_version).count
      meta = {
        name: av.app_version
      }
      self.create_period_data_object(stat_type, festival_id, cumulative_total, period_total, meta)
    end
	end

	# create an array of JSON objects, one for each stat_type for the period
	# stat_type						The name of the stat (string)
	# festival_id					id of the festival (int)
	# cumulative_total		cumulative total (int)
	# period_total				total in this period (int)
	# meta								a json object of meta realted to this stat_type (json)
	def self.create_period_data_object stat_type, festival_id, cumulative_total, period_total, meta=nil
		@period_data << {
			stat_type: stat_type,
			cumulative_total: cumulative_total,
			period_total: period_total,
			meta: meta
		}
	end

	# persist the StatsCache record
	# festival_id					id of the festival (int)
	def self.store_stat festival_id, period_length
		sc = StatsCache.create!(
			period_length: period_length,
			festival_id: festival_id,
			period_data: @period_data, 
			created_at: @now
		)
	end

	# roll up stats for viewing stats over longer time periods
	def self.rollup_stats festival_id, timeframe, now=DateTime.now
		@now = now.beginning_of_hour
		@period_data = []

		if timeframe === 'hour'
			# Get stats_caches that have been created during the last hour
			stats_caches = StatsCache.where(festival_id: festival_id)
								.where(period_length: "10m")
								.where("created_at > ?",now.beginning_of_hour)
								.where("created_at < ?",now.end_of_hour)
								.order("created_at ASC")

			# Get all stat types (using all stats_caches to make sure no new stat_types aren't missed by assuming the first hour contains all data)
			stat_types = []
			stats_caches.each do |sc|
				stat_types << sc.period_data.collect{|stat| stat['stat_type']}
			end
			# Deduplicate
			stat_types = stat_types.flatten.uniq
			# For each stat type calculate the period_total (sum of all period_totals) and cumulative_total (from last object)
			stat_types.each do |st|
				st_data = stats_caches.collect{|s| s.period_data.find{|pd| pd["stat_type"] === st.to_s}}.compact

				period_total = st_data.sum{|st| st["period_total"]}
				cumulative_total = st_data.last["cumulative_total"]

				self.create_period_data_object(st, festival_id, cumulative_total, period_total)
			end

			self.store_stat festival_id, "1h"
		elsif timeframe === 'day'
			# Get stats_caches that have been created during the last day
			stats_caches = StatsCache.where(festival_id: festival_id)
								.where(period_length: "1h")
								.where("created_at > ?",now.beginning_of_day)
								.where("created_at < ?",now.end_of_day)
								.order("created_at ASC")

			# Get all stat types (using all stats_caches to make sure no new stat_types aren't missed by assuming the first hour contains all data)
			stat_types = []
			stats_caches.each do |sc|
				stat_types << sc.period_data.collect{|stat| stat['stat_type']}
			end
			# Deduplicate
			stat_types = stat_types.flatten.uniq
			# For each stat type calculate the period_total (sum of all period_totals) and cumulative_total (from last object)
			stat_types.each do |st|
				st_data = stats_caches.collect{|s| s.period_data.find{|pd| pd["stat_type"] === st.to_s}}.compact

				period_total = st_data.sum{|st| st["period_total"]}
				cumulative_total = st_data.last["cumulative_total"]

				self.create_period_data_object(st, festival_id, cumulative_total, period_total)
			end

			self.store_stat festival_id, "1d"
		end
	end
end