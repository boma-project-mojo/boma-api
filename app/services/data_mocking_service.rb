# Data Mocking Service
#
# ****This service is a WIP dev utiltiy and should be treated as untested.*****  
#
# It provides a way of creating
#
# stub data for testing.  

class DataMockingService

	def self.mock_articles festival_id, amount_of_records
		(1..amount_of_records).each do |mock_article|
			mock_article = Festival.find(festival_id).articles.create! remote_image_url: "https://picsum.photos/400", article_type: :boma_article, title: rand(269033334).to_s, content: rand(269033334).to_s
			mock_article.publish!
		end
	end

	def self.mock_community_articles festival_id, amount_of_records
		(0..amount_of_records).each do |mock_community_article|
			mock_article = Festival.find(festival_id).articles.create! remote_image_url: "https://picsum.photos/400", article_type: :community_article
			# mock_article.publish!
		end
	end

	def self.mock_events festival_id, amount_of_records
		ActiveRecord::Base.logger = nil

		mock_venues = []
		mock_productions = []
		mock_events = []

		mock_venue = nil
		mock_production = nil

    description = "<p>Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Vestibulum tortor quam, feugiat vitae, ultricies eget, tempor sit amet, ante. Donec eu libero sit amet quam egestas semper. Aenean ultricies mi vitae est. Mauris placerat eleifend leo.</p>"

		(1..amount_of_records).each_with_index do |mock_event, index|
			if index % 2 === 0
				mock_venue = Festival.find(festival_id).venues.create! name: rand(269033334).to_s, remote_image_url: "https://picsum.photos/400", description: description, venue_type: "performance", list_order: 1
				mock_venues << mock_venue
			end

			if index % 2 === 0
				mock_production = Festival.find(festival_id).productions.create! remote_image_url: "https://picsum.photos/400", name: rand(269033334).to_s, description: description, aasm_state: :locked
			end

      productions = []
      productions << mock_production

			mock_event = Festival.find(festival_id).events.create! start_time: DateTime.now+1.week+index.hours, end_time: DateTime.now+1.week+index.hours+30.minutes, venue: mock_venue, aasm_state: :published, production_id: mock_production.id, productions: productions

			mock_production.publish_without_validation! unless mock_production.published?
			
			print "\r#{index+1}/#{amount_of_records}"

			mock_productions << mock_production
			mock_events << mock_event
		end

		return {
			venues: mock_venues,
			productions: mock_productions,
			events: mock_events
		}
	end

	def self.mock_organisation_and_festivals
		o = Organisation.create! name: "org_1_1"
	
		(0..5).each do |i|
			f = o.festivals.create! remote_image_url: "https://picsum.photos/400", name: rand(269033334).to_s, start_date: DateTime.now, end_date: DateTime.now+1.week, timezone: "Europe/London"
			self.mock_events f.id, 1000
			self.mock_articles f.id, 1000
		end
	end

	def self.mock_push_notifications address, festival_id
		# check that config in app is organiastion id=1 and festival_id=3 otherwise

		# If complains about existing push notifications then use the following to nuke all
		# a.push_notifications.with_deleted.each {|pn| pn.destroy_fully!}

		# festival_id not implemented....

		# Message
		PushNotificationsService.create_draft_push_notification_for_address("Welcome", "Welcome", address, Festival.find(festival_id).messages.first, "critical_comms", address.organisation_address_from_festival_id(festival_id), Festival.find(festival_id).messages.first.id)

		# Audio Article (Festival)
		PushNotificationsService.create_draft_push_notification_for_address("Audio", "Audio", address, Festival.find(festival_id).articles.where(article_type: :boma_audio_article).where(aasm_state: :published).last, "critical_comms", address.organisation_address_from_festival_id(festival_id), Festival.find(festival_id).messages.first.id)

		# Audio Article (Organisation)
		PushNotificationsService.create_draft_push_notification_for_address("Audio", "Audio", address, Organisation.find(organisation_id).articles.where(article_type: :boma_audio_article).where(aasm_state: :published).offset(10).first, "critical_comms", address.organisation_address_from_festival_id(festival_id), Festival.find(festival_id).messages.last.id)

		# News Article
		PushNotificationsService.create_draft_push_notification_for_address("News", "News", address, Festival.find(festival_id).articles.where(article_type: :news_article).where(aasm_state: :published).first, "critical_comms", address.organisation_address_from_festival_id(festival_id), Festival.find(festival_id).messages.last.id)

		# Community Event
		PushNotificationsService.create_draft_push_notification_for_address("Community Event", "Community Event", address, Festival.find(festival_id).events.community_events.where("start_time > ?", DateTime.now).where(aasm_state: :published).first, "critical_comms", address.organisation_address_from_festival_id(festival_id), Festival.find(festival_id).messages.last.id)

		# Event
		PushNotificationsService.create_draft_push_notification_for_address("Event", "Event", address, Festival.find(festival_id).events.published.first, "critical_comms", address.organisation_address_from_festival_id(festival_id), Festival.find(festival_id).messages.last.id)

		# Now use to send notifications
		# PushNotificationsService.approve_all_drafts_for_address_and_send address.id
	end

	def self.mock_activity now=DateTime.now-4.hours
		# create loads of fake activity reports for the last day

		# For every 10 minutes in the last day create activity then cache

		time = now+10.minutes

		if time < DateTime.now
			puts "mocking data for #{time}"

			festival = Festival.find(3)

			a = Address.first

			Address.order("RANDOM()").limit(rand(10)).each do |a|
				@activity = Activity.where(address_id: a.id).where(festival_id: festival.id).where(activity_type: :app_usage).first_or_initialize

				if @activity.reported_data
					@activity.reported_data["ping"]["total_all"] = @activity.reported_data["ping"]["total_all"] + rand(200)
					@activity.reported_data["view"]["event"]["total"] = @activity.reported_data["view"]["event"]["total"] + rand(200)
					@activity.reported_data["view"]["event"]["event_type"]["boma_event"] = @activity.reported_data["view"]["event"]["event_type"]["boma_event"] + rand(200) if @activity.reported_data["view"]["event"]["event_type"]["boma_event"]
					@activity.reported_data["view"]["event"]["event_type"]["community_event"] = @activity.reported_data["view"]["event"]["event_type"]["community_event"] + rand(200)
					@activity.reported_data["view"]["article"]["total"] = @activity.reported_data["view"]["article"]["total"] + rand(200)
					@activity.reported_data["view"]["article"]["article_type"]["boma_article"] = @activity.reported_data["view"]["article"]["article_type"]["boma_article"] + rand(200)
					@activity.reported_data["view"]["article"]["article_type"]["community_article"] = @activity.reported_data["view"]["article"]["article_type"]["community_article"] + rand(200)
					@activity.reported_data["view"]["article"]["tags"]["215"] = @activity.reported_data["view"]["article"]["tags"]["215"] + rand(200)
					@activity.reported_data["view"]["article"]["tags"]["216"] = @activity.reported_data["view"]["article"]["tags"]["216"] + rand(200)
					@activity.reported_data["view"]["article"]["tags"]["223"] = @activity.reported_data["view"]["article"]["tags"]["223"] + rand(200)
				
					@activity.reported_data["love"]["event"]["total"] = @activity.reported_data["love"]["event"]["total"] + rand(200)
					@activity.reported_data["love"]["event"]["event_type"]["boma_event"] = @activity.reported_data["love"]["event"]["event_type"]["boma_event"] + rand(200)
					@activity.reported_data["love"]["event"]["event_type"]["community_event"] = @activity.reported_data["love"]["event"]["event_type"]["community_event"] + rand(200)
					@activity.reported_data["love"]["event"]["tags"]["144"] = @activity.reported_data["love"]["event"]["tags"]["144"] + rand(200)
					@activity.reported_data["love"]["event"]["tags"]["150"] = @activity.reported_data["love"]["event"]["tags"]["150"] + rand(200)
					@activity.reported_data["love"]["article"]["total"] = @activity.reported_data["love"]["article"]["total"] + rand(200)
					@activity.reported_data["love"]["article"]["article_type"]["boma_article"] = @activity.reported_data["love"]["article"]["article_type"]["boma_article"] + rand(200)
					@activity.reported_data["love"]["article"]["article_type"]["community_article"] = @activity.reported_data["love"]["article"]["article_type"]["community_article"] + rand(200)
					@activity.reported_data["love"]["article"]["tags"]["215"] = @activity.reported_data["love"]["article"]["tags"]["215"] + rand(200)
					@activity.reported_data["love"]["article"]["tags"]["216"] = @activity.reported_data["love"]["article"]["tags"]["216"] + rand(200)
					@activity.reported_data["love"]["article"]["tags"]["223"] = @activity.reported_data["love"]["article"]["tags"]["223"] + rand(200)

				else
					@activity.reported_data = {
						"ping"=>{"total_all"=>rand(200)},
			    	"view"=>{
			    		"event"=>{"total"=>rand(200), "event_type"=>{"boma_event"=>rand(200), "community_event"=>rand(200)}, "tags"=>{}},
			      	"article"=>{"total"=>rand(200), "article_type"=>{"boma_article"=>rand(200), "community_article"=>rand(200)}, "tags"=>{"215"=>rand(200), "216"=>rand(200), "223"=>rand(200)}}
			      },
			    	"love"=>{
			    		"event"=>{"total"=>rand(200), "event_type"=>{"boma_event"=>rand(200), "community_event"=>rand(200)}, "tags"=>{"144"=>rand(200), "150"=>rand(200)}},
			      	"article"=>{"total"=>rand(200), "article_type"=>{"boma_article"=>rand(200), "community_article"=>rand(200)}, "tags"=>{"215"=>rand(200), "216"=>rand(200), "223"=>rand(200)}}
			      }
			    }
				end

				@activity.organisation_id = festival.organisation_id
			
				@activity.save
			end

			StatsCacheService.cache_stats time
			self.mock_activity time	
		end

	end

	def self.reconstruct_new_users_data
		f = Festival.find(11)
		# Festival.all.each do |f|
			oa = OrganisationAddress.where(organisation_id: f.organisation_id).order(:created_at)

			start_time = oa.first.created_at 

			while start_time < DateTime.now
				start_time = start_time + 10.minutes
				StatsCacheService.cache_stats start_time
			end
		# end
	end

	def self.mock_all_image_states
		data = self.mock_events(Organisation.find(7).festivals.last.id, 6)
		# Venue
		# Image in bundle
		data[:venues][0].bundle_image
		data[:venues][0].touch_image_bundled_at!
		# Image was in bundle and has been updated
		data[:venues][1].bundle_image
		data[:venues][1].touch_image_bundled_at!
		data[:venues][1].update! remote_image_url: "https://picsum.photos/400"
		# Image was never in bundle
		# data[:venues][2] venue should never be in bundle
		puts "#{data[:venues][0].name} should load the image from the bundle"
		puts "#{data[:venues][1].name} should cache a new image and fallback to the bundled image"
		puts "#{data[:venues][2].name} should cache a new image and fallback to a default image"

		# Productions / Events
		# Image in bundle
		data[:productions][0].bundle_image
		data[:productions][0].touch_image_bundled_at!
		# Image was in bundle and has been updated
		data[:productions][1].bundle_image
		data[:productions][1].touch_image_bundled_at!
		data[:productions][1].update! remote_image_url: "https://picsum.photos/400"
		# Image was never in bundle
		# data[:venues][2] venue should never be in bundle

		puts "#{data[:productions][0].name} should load the image from the bundle"
		puts "#{data[:productions][1].name} should cache a new image and fallback to the bundled image"
		puts "#{data[:productions][2].name} should cache a new image and fallback to a default image"
	
		# Articles
		articles = mock_articles(Organisation.find(7).festivals.last.id, 1)

		puts "#{articles[0]} should load the image from s3"
	end

end
