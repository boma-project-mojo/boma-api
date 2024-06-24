class MediaConverterWorker
  include Sidekiq::Worker

  def perform(*args)
  	upload_id = args[0]
  	upload_type = args[1]
  	mc = MediaConverterService.new(upload_id)
		if upload_type === 'video'
			mc.process_video
		elsif upload_type === 'audio'
			mc.process_audio
		end
  end
end
