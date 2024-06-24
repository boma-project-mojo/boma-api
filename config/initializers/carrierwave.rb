CarrierWave.configure do |config|
  unless Rails.env.test?
    config.root = Rails.root.join('tmp')
    config.cache_dir = 'carrierwave'
    
    config.fog_provider = 'fog/aws'
    config.fog_credentials = {
      provider:              'AWS',
      aws_access_key_id:     ENV['S3_KEY'],
      aws_secret_access_key: ENV['S3_SECRET'],
      region:                ENV['S3_REGION'],
    }
    config.fog_directory  = ENV['S3_IMAGES_BUCKET_NAME']
    config.asset_host = ENV['CLOUDFRONT_URL']
  else
    CarrierWave.configure do |config|
      config.storage = :file
      config.enable_processing = false
    end
  end
end

module CarrierWave
  module MiniMagick
    def quality(percentage)
      manipulate! do |img|
        img.quality(percentage.to_s)
        img = yield(img) if block_given?
        img
      end
    end
  end
end