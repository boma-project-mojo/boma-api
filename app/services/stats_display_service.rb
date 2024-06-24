class StatsDisplayService

	def initialize festival_id, from, to, time_config, stats=nil
		@from = from
		@to = to
		@time_config = time_config

		# convert chart.js axis_config into the format we require to return the correct StatsCache period_length
		period_length = case @time_config[:unit]
      when 'minute'
        "10m"
      when 'hour'
        "1h"
      when 'day'
        "1d"
      end

		@stats = StatsCache.where(festival_id: festival_id).where("created_at > ?", from).where("created_at < ?", to).where(period_length: period_length).order("created_at ASC") unless stats
		@labels = @stats.collect{|s| s.created_at.strftime("%Y-%m-%d %H:%M %Z")}
		@stat_types_config = {
			"app_pings": {
				name: "App Opens",
				borderColor: "rgb(236,206,81)",
				borderWidth: 3
			},
			"love_by_event": {
				name: "Love for Events",
				borderColor: "rgb(81,138,247)",
			},
			"love_by_article": {
				name: "Love for Articles",
				borderColor: "rgb(145,112,177)",
			},
			"views_by_event": {
				name: "Views for Events",
				borderColor: "rgb(78,161,144)",
			},
			"views_by_article": {
				name: "Views for Article",
				borderColor: "rgb(203,78,81)",
			},
			"views_by_production": {
				name: "Views for Acts",
				borderColor: "rgb(100,21,84)",
			},
			"love_by_event_type": {
				name: "Love for Event Type ",
				borderColor: "rgb(255, 99, 132)",
			},
			"love_by_article_type": {
				name: "Love for Article Type ",
				borderColor: "rgb(255, 99, 132)",
			},
			"views_by_event_type": {
				name: "Views of Event Type ",
				borderColor: "rgb(255, 99, 132)",
			},
			"views_by_article_type": {
				name: "Views of Article Type ",
				borderColor: "rgb(255, 99, 132)",
			},
			"new_users": {
				name: "New Users ",
				borderColor: "rgb(255,99,132)",
			}
		}
		@colours = [
			"rgb(53, 67, 111)",
			"rgb(197, 183, 92)",
			"rgb(137, 177, 168)",
			"rgb(136, 111, 240)",
			"rgb(115, 157, 226)",
			"rgb(104, 101, 119)",
			"rgb(187, 184, 62)",
			"rgb(140, 87, 42)",
			"rgb(88, 230, 226)",
			"rgb(243, 127, 43)",
			"rgb(252, 214, 187)",
			"rgb(158, 171, 68)",
			"rgb(235, 16, 56)",
			"rgb(186, 59, 181)",
			"rgb(228, 253, 15)",
			"rgb(210, 220, 78)",
			"rgb(233, 42, 67)",
			"rgb(221, 196, 151)",
			"rgb(224, 87, 204)",
			"rgb(67, 87, 60)",
			"rgb(146, 107, 193)",
			"rgb(181, 96, 136)",
			"rgb(87, 195, 236)",
			"rgb(87, 118, 153)",
			"rgb(49, 190, 230)",
			"rgb(231, 26, 138)",
			"rgb(132, 136, 142)",
			"rgb(189, 124, 201)",
			"rgb(203, 86, 157)",
			"rgb(251, 95, 135)",
			"rgb(49, 213, 79)",
			"rgb(255, 157, 218)",
			"rgb(255, 220, 183)",
			"rgb(226, 84, 141)",
			"rgb(160, 162, 55)",
			"rgb(187, 41, 227)",
			"rgb(240, 140, 43)",
			"rgb(53, 136, 157)",
			"rgb(249, 88, 111)",
			"rgb(188, 40, 108)",
			"rgb(147, 81, 230)",
			"rgb(219, 251, 136)",
			"rgb(152, 188, 210)",
			"rgb(140, 74, 150)",
			"rgb(186, 140, 44)",
			"rgb(47, 218, 134)",
			"rgb(144, 87, 87)",
			"rgb(114, 102, 137)",
			"rgb(55, 125, 184)",
			"rgb(53, 125, 83)",
			"rgb(105, 238, 231)",
			"rgb(227, 158, 249)",
			"rgb(110, 114, 252)",
			"rgb(195, 220, 66)",
			"rgb(151, 102, 223)",
			"rgb(90, 243, 233)",
			"rgb(217, 245, 65)",
			"rgb(194, 247, 109)",
			"rgb(205, 182, 127)",
			"rgb(230, 88, 156)",
			"rgb(200, 200, 241)",
			"rgb(142, 146, 160)",
			"rgb(141, 243, 239)",
			"rgb(169, 238, 75)",
			"rgb(76, 248, 247)",
			"rgb(112, 241, 214)",
			"rgb(131, 115, 134)",
			"rgb(137, 86, 241)",
			"rgb(253, 215, 89)",
			"rgb(157, 122, 126)",
			"rgb(165, 184, 97)",
			"rgb(219, 174, 166)",
			"rgb(243, 134, 126)",
			"rgb(154, 91, 208)",
			"rgb(109, 154, 106)",
			"rgb(177, 234, 138)",
			"rgb(87, 80, 192)",
			"rgb(248, 191, 184)",
			"rgb(108, 84, 80)",
			"rgb(102, 82, 98)",
			"rgb(135, 232, 174)",
			"rgb(253, 102, 180)",
			"rgb(95, 120, 134)",
			"rgb(173, 179, 117)",
			"rgb(120, 123, 160)",
			"rgb(128, 87, 164)",
			"rgb(255, 211, 105)",
			"rgb(132, 193, 113)",
			"rgb(96, 234, 180)",
			"rgb(245, 172, 114)",
			"rgb(98, 208, 144)",
			"rgb(251, 124, 230)",
			"rgb(216, 217, 128)",
			"rgb(214, 212, 125)",
			"rgb(228, 143, 211)",
			"rgb(203, 155, 142)",
			"rgb(127, 214, 119)",
			"rgb(215, 237, 117)",
			"rgb(176, 175, 131)",
			"rgb(224, 122, 197)",
			"rgb(145, 120, 152)"
		]
	end

	# all stats for main chart in admin section 
	# festival_id 		id of Festival (int)
	# from  					datetime as unix timestamp
	# to   						datetime as unix timestamp
	def stats_for_main_chart festival_id, from, to, axis_config
		datasets = []

		stat_types = [:app_pings, :love_by_event, :love_by_article, :views_by_event, :views_by_article, :views_by_production]

		stat_types.each do |st|
			label = @stat_types_config[st][:name] rescue key
			borderColor = @stat_types_config[st][:borderColor] rescue "rgb(255, 99, 132)"
			borderWidth = @stat_types_config[st][:borderWidth]

			datasets << {
				borderColor: borderColor,
				label: label,
				fill: false,
				data: @stats.collect{|s| 
					# collect the stat created_at date and the object of stats for this stat type
					[s.created_at, s.period_data.find{|pd| pd["stat_type"] === st.to_s}]
				}.collect{|st| 
					# build an array of created_at labels for the X axis and period_totals for the y axis
					# the conditional statement handles 
					# a) the situation where an object of stats doesn't exist for this stat_type at this time and
					# b) doesn't allow minus figures to show as there is a bug in the production app which sometimes reports minus stats
					[st[0], (st[1] === nil or st[1]['period_total'] < 0) ? 0 : st[1]['period_total'] ] 
				},
				spanGaps: true,
				borderWidth: borderWidth || 1
			}
		end

		return {
			# labels: @labels,
			datasets: datasets,
			axis_config: axis_config
		}
	end

	# all stats for users chart in admin section 
	# festival_id 		id of Festival (int)
	# from  					datetime as unix timestamp
	# to   						datetime as unix timestamp
	def stats_for_users festival_id, from, to, axis_config
		datasets = []

		stat_types = [:new_users]

		stat_types.each do |st|
			
			label = @stat_types_config[st.to_sym][:name] rescue st
			borderColor = @stat_types_config[st.to_sym][:borderColor] rescue "rgb(255, 99, 132)"
			borderWidth = @stat_types_config[st.to_sym][:borderWidth]

			datasets << {
				borderColor: borderColor,
				label: label,
				fill: false,
				data: @stats.collect{|s| 
					# collect the stat created_at date and the object of stats for this stat type
					[s.created_at, s.period_data.find{|pd| pd["stat_type"] === st.to_s}]
				}.collect{|st| 
					# build an array of created_at labels for the X axis and period_totals for the y axis
					# the conditional statement handles 
					# a) the situation where an object of stats doesn't exist for this stat_type at this time and
					# b) doesn't allow minus figures to show as there is a bug in the production app which sometimes reports minus stats
					[st[0], (st[1] === nil or st[1]['period_total'] < 0) ? 0 : st[1]['period_total'] ] 
				},
				spanGaps: true,
				borderWidth: borderWidth || 1
			}
		end

		return {
			# labels: @labels,
			datasets: datasets,
			axis_config: axis_config
		}
	end

	# all stats for app_versions chart in admin section 
	# festival_id 		id of Festival (int)
	# from  					datetime as unix timestamp
	# to   						datetime as unix timestamp
	def app_versions festival_id, from, to, axis_config
		datasets = []

    # Get all app versions for this festival
    organisation = Festival.find(festival_id).organisation
    # collect all the app versions for this festival_id with the count of addresses on this version.  
    app_versions_with_counts = organisation.organisation_addresses.group(:app_version).count

    # make an array of stat types for this festival
    stat_types = []
    app_versions_with_counts.each do |av, count|
      next if count < 50
      # disregard app where the total number of addresses on this version is less than 50
      # (these are most likely test version of the app and not relevant to be displayed)
      stat_types << "app_versions_#{av}"
    end

    # Create the dataset for charting for these stat_types
		stat_types.each_with_index do |st, index|
			label = st.humanize
			borderColor = @colours[index]
			borderWidth = 3

			datasets << {
				borderColor: borderColor,
				label: label,
				fill: false,
				data: @stats.collect{|s| 
					# collect the stat created_at date and the object of stats for this stat type
					[s.created_at, s.period_data.find{|pd| pd["stat_type"] === st.to_s}]
				}.collect{|st| 
					# build an array of created_at labels for the X axis and period_totals for the y axis
					# the conditional statement handles 
					# a) the situation where an object of stats doesn't exist for this stat_type at this time and
					# b) doesn't allow minus figures to show as there is a bug in the production app which sometimes reports minus stats
          [st[0], (st[1] === nil or st[1]['cumulative_total'] < 0) ? 0 : st[1]['cumulative_total'] ] 
				},
				spanGaps: true,
				borderWidth: borderWidth || 1
			}
		end

		return {
			datasets: datasets,
			axis_config: axis_config
		}
	end

	# chart data for notifications and published content chart
	# festival_id 		id of Festival (int)
	# from  					datetime as unix timestamp
	# to   						datetime as unix timestamp
	def notifications_and_publishing festival_id, from, to, axis_config
		colours = [
			"rgb(236,206,81)",
			"rgb(81,138,247)",
			"rgb(145,112,177)"
		]

		datasets = []

		stat_types = [:app_notifications]

		# App Notifications
		borderColor = @stat_types_config["new_events_published"][:borderColor] rescue colours[0]

		datasets << {
			type: "line",
			borderColor: borderColor,
			label: "Notifications Sent",
			borderDash: [5, 5],
			data: @stats.collect{|s| s.period_data.find{|pd| pd["stat_type"] === "app_notifications"}}.compact.collect{|st| st["period_total"]},
		}

		# New Events Published
		borderColor = @stat_types_config["new_events_published"][:borderColor] rescue colours[1]

		datasets << {
			borderColor: borderColor,
			label: "New Events Published",
			borderDash: [5, 5],
			fill: false,
			data: @stats.collect{|s| s.period_data.find{|pd| pd["stat_type"] === "new_events_published"}}.compact.collect{|st| st["meta"]["events"]["total_new"]}
		}

		# New Articles Published
		borderColor = @stat_types_config["new_articles_published"][:borderColor] rescue colours[2]

		datasets << {
			borderColor: borderColor,
			label: "New Articles Published",
			borderDash: [5, 5],
			fill: false,
			data: @stats.collect{|s| s.period_data.find{|pd| pd["stat_type"] === "new_articles_published"}}.compact.collect{|st| st["meta"]["articles"]["total_new"]}
		}

		return {
			labels: @labels,
			datasets: datasets,
			axis_config: axis_config
		}
	end

	# chart data for tag chart
	# festival_id 		id of Festival (int)
	# from  					datetime as unix timestamp
	# to   						datetime as unix timestamp
	def stat_types_by_tag_for_chart festival_id, from, to, axis_config
		datasets = []

		# Get festival tags for events and articles
		event_tags = Festival.find(festival_id).tags.where(tag_type: :production).where(aasm_state: :published)
		article_tags = Organisation.find(Festival.find(festival_id).organisation_id).tags.where.not(tag_type: [:production, :retailer, :performance_venue]).where(aasm_state: :published)

		# Create array of data types relevant to the current festival
		data_types = []

		data_types << Festival.find(festival_id).schedule_modal_type
		data_types << 'article' if Festival.find(festival_id).articles.any?

		data_types.each do |dt|
			# Create an array of the stat_types for each data_type for both love and view stats
			view_stat_types = []
			love_stat_types = []

			if(dt === 'event')
				tags = event_tags
			elsif(dt === 'article')
				tags = article_tags
			elsif(dt === 'production')
				tags = event_tags
			end

			tags.each do |t| 
				view_stat_types << "views_by_#{dt}_by_tag_#{t.id}" 
				love_stat_types << "love_by_#{dt}_by_tag_#{t.id}"
			end

			labels = []
			view_figures = []

			view_stat_types.each do |st|
				unless @stats.collect{|s| s.period_data.find{|pd| pd["stat_type"] === st.to_s}}.compact.last.nil?
					tag = tags.find(st.split('_').last)
					labels << tag.name
					view_figures << @stats.collect{|s| s.period_data.find{|pd| pd["stat_type"] === st.to_s}}.compact.last["cumulative_total"]
				end
			end

			if view_figures.count > 0
				data = [{
			    label: "#{dt} views by tag type",
			    data: view_figures,
			    hoverOffset: 4,
			    backgroundColor: @colours,
			    segmentShowStroke: false,
			    borderColor: "rgba(0,0,0,1)"
			  }]

			  datasets << {
					labels: labels,
					datasets: data,
					chartTitle: "#{dt} views by tag type".titleize,
				}
			end

			labels = []
			love_figures = []

			love_stat_types.each do |st|
				unless @stats.collect{|s| s.period_data.find{|pd| pd["stat_type"] === st.to_s}}.compact.last.nil?
					tag = tags.find(st.split('_').last)
					labels << tag.name
					love_figures << @stats.collect{|s| s.period_data.find{|pd| pd["stat_type"] === st.to_s}}.compact.last["cumulative_total"]
				end
			end

			if love_figures.count > 0
				data = [{
			    label: "#{dt} love by Tag Type",
			    data: love_figures,
			    hoverOffset: 4,
			    backgroundColor: @colours,
			    segmentShowStroke: false,
			    borderColor: "rgba(0,0,0,1)"
			  }]

			  datasets << {
					labels: labels,
					datasets: data,
					chartTitle: "#{dt} love by tag type".titleize,
					axis_config: axis_config
				}
			end

		end

		return datasets
	end

	# chart data for model type chart
	# festival_id 		id of Festival (int)
	# from  					datetime as unix timestamp
	# to   						datetime as unix timestamp
	def stats_by_model_type_for_chart festival_id, from, to, axis_config
		datasets = []
		labels = []

		stat_types = [:love_by_event_type_by_boma_event, :views_by_event_type_by_boma_event, :love_by_article_type_by_boma_article, :views_by_article_type_by_boma_article, :love_by_article_type_by_boma_audio_article, :views_by_article_type_by_boma_audio_article, :love_by_article_type_by_boma_news_article, :views_by_article_type_by_boma_news_article]

		i = 0
		stat_types.each do |st|
			i = i+1

			# stats = @stats.collect{|s| s.period_data.find{|pd| pd["stat_type"] === st.to_s}}.compact

			stats = @stats.collect{|s| 
				# collect the stat created_at date and the object of stats for this stat type
				[s.created_at, s.period_data.find{|pd| pd["stat_type"] === st.to_s}]
			}

			if stats.count > 0
				label = stats.last["meta"]["name"] rescue st

				datasets << {
					borderColor: @colours[i],
					label: label,
					fill: false,
					data: stats.collect{|st| 
						# build an array of created_at labels for the X axis and period_totals for the y axis
						# the conditional statement handles 
						# a) the situation where an object of stats doesn't exist for this stat_type at this time and
						# b) doesn't allow minus figures to show as there is a bug in the production app which sometimes reports minus stats						
            [st[0], (st[1] === nil or st[1]['period_total'] < 0) ? 0 : st[1]['period_total'] ] 
					},
					borderWidth: 1
				}
			end
		end

		return {
			# labels: @labels,
			datasets: datasets,
			axis_config: axis_config
		}
	end

	# Cumulative period 
	def cumulative_stats_report festival_id
		stat_types = [:love_by_event, :views_by_event, :views_by_production, :love_by_article, :views_by_article, :app_pings, :app_notifications, :new_users]

		counts = {}

		stat_types.each do |st|
			counts[st] = @stats.last.period_data.find{|pd| pd["stat_type"] === st.to_s}["cumulative_total"] rescue 0
		end

		return counts
	end

end