include ActionView::Helpers::TextHelper

@client = SoundCloud.new({
  :client_id     => ENV['SOUNDCLOUD_CLIENT_ID'],
  :client_secret => ENV['SOUNDCLOUD_CLIENT_SECRET'],
})

@page = 0

@organisation = Organisation.find(8)

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

def get_tracks get
  tracks = @client.get(get, limit: 100, linked_partitioning: true)

  puts "PAGE ->>>>>>>>>>>>>>>> #{@page}"

  tracks[:collection].each do |track|
    begin
      source_id = "sndcld-#{track.id}"

      # name of mix
      title = track.title

      # any description content
      description = track.description
      description = simple_format(description)

      description = description.gsub(URI.regexp(['http', 'https']), '<a href="\0">\0</a>').html_safe

      # image
      image_url = track.artwork_url.gsub('large', 'original')
      # some original artwork returns 403...
      if Faraday.head(image_url).status != 200
        puts "Original image not available, using t500x500"
        image_url = track.artwork_url.gsub('large', 't500x500')
      end

      # # # get filename that youtube-dl will get
      # filename = `youtube-dl #{track.uri} --get-filename`
      # ext = File.extname(filename).squish
      # basename = File.basename(filename,File.extname(filename)).parameterize

      # reconstructing filename
      basename = "#{(track.title+"-"+track.id.to_s).parameterize}"
      ext = ".mp3"
      
      # byebug if rfilename != "#{basename}#{ext}"

      # description = "#{description}"

      # download file
      # download = system "youtube-dl #{track.uri} --output './tmp/#{basename+ext}'"

      # If in production then just set the url to be the location of the file in s3
      s3 = Aws::S3::Resource.new
      upload = s3.bucket(ENV['S3_IMAGES_BUCKET_NAME']).object("boom-audio/#{basename+ext}").public_url

      # # upload to s3
      # s3 = Aws::S3::Resource.new
      # path = "#{Rails.env}/#{SecureRandom.uuid}/#{filename.gsub(/[^0-9a-z\.]/i, '')}"
      # s3.bucket(ENV['S3_IMAGES_BUCKET_NAME']).object(path).upload_file(Rails.root.join('tmp', basename+ext))
      # upload = s3.bucket(ENV['S3_IMAGES_BUCKET_NAME']).object(path).public_url

      # create an article
      @article = @organisation.articles.where(source_id: source_id).first_or_initialize
      @article.article_type = 'boma_audio_article'
      
      if @article.image.url === nil or !same_image?(@article.image.url, image_url)
        @article.remote_image_url = image_url
      end

      @article.image_last_updated_at = DateTime.now
      @article.title = title
      @article.content = description
      @article.created_at = track.created_at

      @article.save!

      # create an upload
      # @upload = @article.uploads.where(upload_type: "audio", uploadable_type: "AppData::Article", uploadable_id: @article.id).first_or_initialize
      # @upload.original_url = upload
      # @upload.save!

    rescue Exception => e
      puts "FAIL - #{e.inspect} - #{track.inspect}"
    end

  end

  @page = @page + 1

  get_tracks(tracks[:next_href])
end

get_tracks("/users/681182/tracks")