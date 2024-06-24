# Media Converter Service
#
# The service exposes functions to process audio and video content into the required formats to play using the 
# in app players included in the client app.  
#
# This service required ffmpeg to be installed on the same server as this rails project.  
# 
# Video is converted into m3u8 format
# Audio is converted into aac format

require 'uri'
require 'm3u8'

class MediaConverterService
  # Initialize the service
  # Params:
  # +upload_id+:: The id of the AppData::Upload
	def initialize upload_id
		@model = AppData::Upload.find(upload_id)
	end

  # Convert the video into m3u8 format
  # Generate the playlist and upload the m3u8 segments and playlist to s3.  
	def process_video
	 	uri = URI.parse(@model.original_url)
		filename = File.basename(uri.path)
		directory = File.basename(filename, File.extname(filename))

	  Dir.mkdir("/tmp/#{directory}") rescue puts "Directory already exists"

	  response = system "ffmpeg -hide_banner -y -i #{@model.original_url} \
			-vf scale='360:trunc(ow/a/2)*2' -c:a aac -ar 48000 -c:v h264 -profile:v main -crf 20 -sc_threshold 0 -g 48 -keyint_min 48 -hls_time 4 -hls_playlist_type vod  -b:v 800k -maxrate 856k -bufsize 1200k -b:a 96k -hls_segment_filename /tmp/#{directory}/360p_%03d.ts /tmp/#{directory}/360p.m3u8 \
			-vf scale='480:trunc(ow/a/2)*2' -c:a aac -ar 48000 -c:v h264 -profile:v main -crf 20 -sc_threshold 0 -g 48 -keyint_min 48 -hls_time 4 -hls_playlist_type vod -b:v 1400k -maxrate 1498k -bufsize 2100k -b:a 128k -hls_segment_filename /tmp/#{directory}/480p_%03d.ts /tmp/#{directory}/480p.m3u8 \
			-vf scale='720:trunc(ow/a/2)*2' -c:a aac -ar 48000 -c:v h264 -profile:v main -crf 20 -sc_threshold 0 -g 48 -keyint_min 48 -hls_time 4 -hls_playlist_type vod -b:v 2800k -maxrate 2996k -bufsize 4200k -b:a 128k -hls_segment_filename /tmp/#{directory}/720p_%03d.ts /tmp/#{directory}/720p.m3u8 \
			-vf scale='1080:trunc(ow/a/2)*2' -c:a aac -ar 48000 -c:v h264 -profile:v main -crf 20 -sc_threshold 0 -g 48 -keyint_min 48 -hls_time 4 -hls_playlist_type vod -b:v 5000k -maxrate 5350k -bufsize 7500k -b:a 192k -hls_segment_filename /tmp/#{directory}/1080p_%03d.ts /tmp/#{directory}/1080p.m3u8"
  
		unless response === false
			playlist = M3u8::Playlist.new

			options = { width: 1920, height: 1080, bandwidth: 5000000, uri: '1080p.m3u8'}
			item = M3u8::PlaylistItem.new(options)
			playlist.items << item

			options = { width: 1280, height: 720, bandwidth: 2800000, uri: '720p.m3u8'}
			item = M3u8::PlaylistItem.new(options)
			playlist.items << item

			options = { width: 842, height: 480, bandwidth: 1400000, uri: '480p.m3u8'}
			item = M3u8::PlaylistItem.new(options)
			playlist.items << item

			options = { width: 640, height: 360, bandwidth: 800000, uri: '360p.m3u8'}
			item = M3u8::PlaylistItem.new(options)
			playlist.items << item

			File.open("/tmp/#{directory}/#{directory}.m3u8", "w+") do |f|
			  playlist.write(f)
			end

			system "aws s3 cp --recursive /tmp/#{directory} s3://#{ENV['S3_IMAGES_BUCKET_NAME']}/uploads/#{@model.uploadable.class.to_s.underscore}/video/#{@model.uploadable.id}/#{directory}";

			@model.update processed_url: "https://#{ENV['S3_IMAGES_BUCKET_NAME']}.s3.#{ENV['S3_REGION']}.amazonaws.com/uploads/#{@model.uploadable.class.to_s.underscore}/video/#{@model.uploadable.id}/#{directory}/#{directory}.m3u8", aasm_state: :processed
  	else
  		# Conversion failed for some reason
  		@model.fail!
  	end
  end

  # Convert the audio into aac format and upload to s3.  
  def process_audio
  	uri = URI.parse(@model.original_url)
		filename = File.basename(uri.path)
		directory = File.basename(filename, File.extname(filename))

	  response = system "ffmpeg -y -i #{@model.original_url} -ar 44100 -ab 48k -c:a aac -aprofile mpeg2_aac_low -ac 1 /tmp/#{directory}.aac"

	  unless response === false
			system "aws s3 cp /tmp/#{directory}.aac s3://#{ENV['S3_IMAGES_BUCKET_NAME']}/uploads/#{@model.uploadable.class.to_s.underscore}/audio/#{@model.uploadable.id}/#{directory}.aac";
  
			@model.update processed_url: "https://#{ENV['S3_IMAGES_BUCKET_NAME']}.s3.#{ENV['S3_REGION']}.amazonaws.com/uploads/#{@model.uploadable.class.to_s.underscore}/audio/#{@model.uploadable.id}/#{directory}.aac", aasm_state: :processed
  	else 
  		# Conversion failed for some reason
  		@model.fail!
  	end
  end

end