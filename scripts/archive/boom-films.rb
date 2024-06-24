# To run this script
#
# 1.  Run the following script in the development env, this will download the webm files using yt-dlp 
#     convert them to mp4 and upload to s3 in the development bucket.  
# 2.  Take note of the manifest file that is printed once the script is complete and store these on line 9 of
# 		this script.   Commit and deploy to production.   
# 3.  Use aws s3 sync to move the videos from the development s3 bucket to production
# 4.  Run this script in production to create the articles and uploads and initate the process of 
# 		converting the videos to a HLS stream.  

include ActionView::Helpers::TextHelper

def same_image?(path1, path2)
  return true if path1 == path2
  
  begin
    open(path1) {|image1| 
      open(path2) {|image2|
        return false if image1.size != image2.size
        while (b1 = image1.read(1024)) and (b2 = image2.read(1024))
          return false if b1 != b2
        end
      }
    }
    true
  rescue
    true
  end
end

@organisation = Organisation.find(8)

json_blob = File.read(Rails.root.join("public/boom-videos.json"))
data = JSON.parse(json_blob);

manifest = {}

manifest_from_development_run = {"WbYgblS-7tU"=>"collectif-cenc-performers-boom-festival-2012-wbygbls-7tu", "jH3tdtZGBbs"=>"dj-tristan-dancetemple-boom-festival-2012-jh3tdtzgbbs", "y6K3tjQQc2g"=>"puppet-at-dance-temple-boom-festival-2012-y6k3tjqqc2g", "7MKhbFJBpkU"=>"art-as-money-talk-at-the-boom-festival-7mkhbfjbpku", "7yhnROalC88"=>"boom-festival-2006-the-full-movie-7yhnroalc88", "Q8tDpQp6m0A"=>"transformational-festivals-jeet-kei-leung-at-tedxvancouver-q8tdpqp6m0a", "tcCOrqbjRhQ"=>"recycling-and-re-using-materials-tccorqbjrhq", "aYgzcM9MwZg"=>"scheffler-mirror-aygzcm9mwzg", "1MT_kbqWqNw"=>"sacred-fire-a-naturalistic-concept-boom-festival-2008-1mt_kbqwqnw", "V5h9CfDM1i0"=>"boom-indie-media-v5h9cfdm1i0", "owdxuuVp8RM"=>"healing-at-boom-owdxuuvp8rm", "csxjz3I5uag"=>"coming-to-boom-by-bike-csxjz3i5uag", "nfCws5mIgS8"=>"a-tribute-to-albert-hofmann-1906-2008-nfcws5migs8", "SV0a9ZxfcCs"=>"a-quiet-place-sv0a9zxfccs", "xBK20TLYars"=>"boom-festival-2014-solar-sonic-timelords-frequency-generators-and-true-solar-power-xbk20tlyars", "dFAPJigZUpM"=>"boom-festival-2014-the-evolution-revolution-from-hostilities-to-harmony-dfapjigzupm", "eHW0HEisUo4"=>"boom-festival-2014-opening-pandora-s-box-why-the-tech-dream-has-turned-into-a-nightmare-ehw0heisuo4", "ucK7ZU-ZEEw"=>"boom-festival-2014-the-physics-of-fractal-consciousness-uck7zu-zeew", "aFXAqOJRnHI"=>"boom-festival-2014-christiania-a-festival-365-days-a-year-afxaqojrnhi", "Q-39-6YKUao"=>"boom-festival-2014-official-webdoc-4-arts-music-q-39-6ykuao", "JT9FbGjwpPM"=>"boom-festival-2014-reclaiming-the-earth-steps-towards-a-collective-awakening-jt9fbgjwppm", "4rHhHc35dao"=>"boom-festival-2014-the-evolutionary-impulse-of-psytrance-music-4rhhhc35dao", "VpTvIzOqRBY"=>"boom-festival-2014-keeping-it-real-sustainability-in-large-scale-events-vptvizoqrby", "5LWBu4UBw1A"=>"boom-festival-2014-official-webdoc-5-love-5lwbu4ubw1a", "RvjcC6RU7U0"=>"boom-festival-2014-free-cultural-spaces-reflections-dreams-comments-ideas-feelings-rvjcc6ru7u0", "4Va6jY_0Fuc"=>"psychedelic-science-manual-of-psychedelic-support-4va6jy_0fuc", "dMCV-9BmRaM"=>"psychedelic-science-rick-doblin-maps-interview-part-1-dmcv-9bmram", "K8_wJrjVkDk"=>"psychedelic-science-rick-doblin-maps-interview-part-2-k8_wjrjvkdk", "xWod1TlQhHA"=>"in-the-studio-penta-xwod1tlqhha", "OlBbdWKlNCM"=>"kaleidoscopic-sounds-part-1-boom-radio-psychedelic-music-diggin-olbbdwklncm", "i2mR2IR-g8E"=>"kaleidoscopic-sounds-part-2-boom-radio-psychedelic-music-diggin-i2mr2ir-g8e", "DwA0SBHomMU"=>"psychedelic-history-beat-generation-dwa0sbhommu", "eFXhTvVzjm0"=>"android-jones-electro-mineralist-expression-efxhtvvzjm0", "nXm9meVaZ50"=>"alternative-models-yoga-into-the-slums-nxm9mevaz50", "vB2vUSPVaMw"=>"in-the-studio-burn-in-noise-vb2vuspvamw", "T7o-fV2y3VQ"=>"boom-festival-2014-tales-from-the-road-the-incredible-adventures-of-the-boom-by-bike-heros-t7o-fv2y3vq", "JNAnqnEs3S8"=>"boom-festival-2014-discussion-panel-boom-fusion-burning-man-jnanqnes3s8", "BtinRGmogOA"=>"liminal-village-2016-beautiful-trouble-creative-resistance-to-a-commodified-world-btinrgmogoa", "Qoed29syeek"=>"liminal-village-2016-production-of-psytrance-qoed29syeek", "OcRFchLbtq0"=>"liminal-village-2016-biohacking-ocrfchlbtq0", "N9HLQ4CHHHU"=>"liminal-village-2016-the-local-food-renaissance-through-technology-and-communities-n9hlq4chhhu", "rZ2f_JgPwEs"=>"liminal-village-2016-boom-sustainability-rz2f_jgpwes", "Lnud76TFqBc"=>"eco-practices-series-a-conscious-approach-to-nutrition-lnud76tfqbc", "GMgfZCq0OX0"=>"boom-state-of-mind-connect-by-disconnecting-gmgfzcq0ox0", "RneMSikf18I"=>"eco-practices-series-dry-compost-toilets-rnemsikf18i", "BjCiDxz8rTQ"=>"eco-practices-series-public-transport-bjcidxz8rtq", "ghCueUS4Yyg"=>"human-sustainability-substance-use-ghcueus4yyg", "qECVlONjdEo"=>"eco-practices-series-skip-on-plastic-qecvlonjdeo", "_zqdf2YKxSc"=>"boom-state-of-mind-good-practices-_zqdf2ykxsc", "1wrgYoeWZuI"=>"eco-practices-series-fire-prevention-safety-measures-1wrgyoewzui", "baHZiwjHZP8"=>"eco-practices-series-skip-on-plastic-2-bahziwjhzp8", "GjgsdDuM22w"=>"boom-festival-2018-day-4-gjgsddum22w", "SkJB1Q5sU-4"=>"liminal-village-2018-psychedelic-humanism-from-individual-experience-to-human-engagement-skjb1q5su-4", "6bjuBF37jEU"=>"your-oil-is-music-a-new-energy-concept-on-entertainment-6bjubf37jeu", "MovI853SlJE"=>"boom-festival-2018-day-6-movi853slje", "RxNipLt6UnM"=>"boom-festival-2018-day-8-rxniplt6unm", "3OzPH5y2ZeU"=>"boom-toolkit-for-covid-19-1-freedom-and-mass-digital-surveillance-3ozph5y2zeu", "m1wwjQUeUhk"=>"boom-toolkit-for-covid-19-2-the-role-of-art-and-artists-m1wwjqueuhk", "XiLHxPTLZHc"=>"boom-toolkit-for-covid-19-3-insights-from-a-scientist-xilhxptlzhc", "VaoJam9tQjU"=>"boom-toolkit-for-covid-19-4-an-indigenous-leader-s-perspective-vaojam9tqju", "s1SDk21N8Ho"=>"boom-toolkit-for-covid-19-5-spiritual-perspectives-s1sdk21n8ho", "RlRmAx80Mqg"=>"boom-toolkit-for-covid-19-6-rethinking-food-systems-rlrmax80mqg", "az5DOqM1nLI"=>"boom-toolkit-for-covid-19-7-impact-of-covid-19-on-a-psychedelic-music-artist-az5doqm1nli", "RHVAWeC01Z4"=>"boom-toolkit-for-covid-19-8-perspectives-from-an-electronic-music-promoter-rhvawec01z4", "IZxhZcp-Krs"=>"boom-toolkit-for-covid-19-9-reflections-on-sustainability-festivals-covid-19-izxhzcp-krs", "PUitF3kVHtU"=>"boom-toolkit-for-covid-19-11-mental-health-in-the-music-industry-amid-a-pandemic-puitf3kvhtu", "lrz7rSOVfjA"=>"boom-festival-liminal-podquest-3-nerd-immunity-collective-wisdom-conspiracy-theories-lrz7rsovfja", "nkD9eGkiOQk"=>"boom-toolkit-for-covid-19-12-alternative-approaches-to-fight-the-pandemic-nkd9egkioqk", "KEBf163JgGM"=>"boom-toolkit-for-covid-19-13-coping-with-the-pandemic-through-art-kebf163jggm", "KuNet2y9NUg"=>"boom-toolkit-for-covid-19-14-forest-therapy-practical-steps-with-nature-to-handle-the-pandemic-kunet2y9nug", "ZisD7z4uPTg"=>"boom-toolkit-for-covid-19-15-lack-of-biodiversity-covid-19-zisd7z4uptg", "oAU4JaAUZNw"=>"boom-festival-zen-baboon-boomstream-2021-oau4jaauznw", "OAzJE1X7LXA"=>"boom-festival-boundless-boomstream-2021-oazje1x7lxa", "sFt2fWr0uWQ"=>"boom-festival-avalon-boomstream-2021-sft2fwr0uwq", "8yEPGXhwuCk"=>"boom-festival-ulvae-boomstream-2021-8yepgxhwuck", "tujmXUEAIUo"=>"boom-festival-code-therapy-boomstream-2021-tujmxueaiuo", "tFGSssR9VWA"=>"boom-festival-nuky-boomstream-2021-tfgsssr9vwa", "0KfkGRpE3Ug"=>"summer-2020-at-boomland-0kfkgrpe3ug"}

data['data']['webtvPage']['list'].each do |video|
	begin
		puts "Processing #{video['youtube_video_id']}"

		# id
		id = video['youtube_video_id']
		source_id = "yt-#{id}"

		# This video id has an & in it and is screwing my script up!
		next if id === '2iyBziIOecU&t'

		# find or init the article
		@article = @organisation.articles.where(source_id: source_id).first_or_initialize

		article_uploads = @article.uploads.where(upload_type: :video)

    # if the video article already exists in the database move on
		# unless @article.new_record? and article_uploads.count === 0
		# 	puts "Record already in database"
		# 	next
		# end

    if Rails.env.development?
    	# no yt-dlp buildback exists for heroku at time of writing, instead the workaround is to download the videos
    	# locally, upload then to s3. 
    	# 
    	# this script also generates a manifest which links youtube id to object name at s3

  		# get file details to create safe filename for s3
			# filename = `youtube-dl #{id} --get-filename`
			filename = `yt-dlp #{id} --get-filename`
			ext = File.extname(filename).squish
			basename = File.basename(filename,File.extname(filename)).parameterize

			# download file
			# download = system "yt-dlp #{id} --output './tmp/#{basename+ext}'"

			# convert webm to mp4
  		system "ffmpeg -n -i './tmp/#{basename+ext}' -c copy './tmp/#{basename}.mp4'"

			# upload to s3
			s3 = Aws::S3::Resource.new
			path = "boom-videos/#{basename}.mp4"
			
			unless(s3.bucket(ENV['S3_IMAGES_BUCKET_NAME']).object(path).exists?)
				s3.bucket(ENV['S3_IMAGES_BUCKET_NAME']).object(path).upload_file(Rails.root.join('tmp', basename+".mp4"))
				upload = s3.bucket(ENV['S3_IMAGES_BUCKET_NAME']).object(path).public_url
			else
				puts "Already uploaded to s3, skipping"
			end
			manifest[id] = basename
    else
    	# If in production, create the article and upload models and link to associated boom-video object url to the 
    	# upload ready for processing. 
			yt_video_object = Yt::Video.new id: id

    	# title
			title = yt_video_object.title

			# content
			content = yt_video_object.description
	    content = simple_format(content)
	    content = content.gsub(URI.regexp(['http', 'https']), '<a href="\0">\0</a>').html_safe

			# created_at
			created_at = yt_video_object.published_at

			# thumbnail
			# image_url = yt_video_object.snippet.thumbnails['maxres']['url'] rescue yt_video_object.snippet.thumbnails["high"]["url"]
			image_url = video['images'][0]['httpUrl']

			# get the file basename from the manifest file that comes from the development component
			# of this script
			basename = manifest_from_development_run[id]

    	s3 = Aws::S3::Resource.new
			upload = s3.bucket(ENV['S3_IMAGES_BUCKET_NAME']).object("boom-videos/#{basename}.mp4").public_url

    	# create an article
			@article.resize_to_fit = true
			@article.article_type = 'boma_video_article'

		  if Faraday.head(image_url).status != 200
	      puts "Original image not available, using t500x500"
	      image_url = "https://img.youtube.com/vi/#{id}/sddefault.jpg"
	    end

	    if @article.image.url === nil or !same_image?(@article.image.url, image_url)
				@article.remote_image_url = image_url
			end

			@article.image_last_updated_at = DateTime.now
			@article.title = title
			@article.content = content
			@article.created_at = created_at

			# Split the path of the video to create the relevant tags, if the tag exists add it to the article
    	tags = video["path"].split('/')
    	tags.each do |tag|
    		t = @organisation.tags.find_by_name(tag.underscore.humanize.titlecase)
    		@article.tags << t unless t.nil?
    	end	

			@article.save!

			# create an upload
		  @upload = @article.uploads.where(upload_type: "video", uploadable_type: "AppData::Article", uploadable_id: @article.id).first_or_initialize
	    @upload.original_url = upload
	    @upload.save!
    end
	rescue Exception => e
		puts "FAIL - #{e.inspect} - #{video.inspect}"
	end
end

if Rails.env.development?
	puts manifest.inspect
	puts "\n\n\n"
	puts "
		Now use aws s3 sync to move mp4s from #{ENV['S3_IMAGES_BUCKET_NAME']} to the production bucket.  
		\n\n
		You also need to save the above manifest and include it in the production section of this script, commit and deploy to production before running this script again in production env.mp4
		"
end