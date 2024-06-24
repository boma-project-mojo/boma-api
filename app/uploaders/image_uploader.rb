class ImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
  
  unless Rails.env.test?
    storage :fog
  else
    storage :file
  end

  # Limit file size of images to 10MB
  def size_range
    1.byte..10.megabytes
  end
    
  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def cache_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url(*args)
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # ActionController::Base.helpers.asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  # Process files as they are uploaded:
  # process scale: [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  version :original

  version :loader do
    process resize_to_fill_or_fit: [20, 20]
    process :quality => 25 
  end

  version :thumb do
    process resize_to_fill_or_fit: [414, 414]
    process :quality => 75
  end

  version :small_thumb do
    process resize_to_fill_or_fit: [212, 212]
  end

  version :medium do
    process resize_to_fill_or_fit: [650, 650]
  end

  protected

  def resize_to_fill_or_fit width, height
    if model.resize_to_fit
      resize_to_fit(width,height)
    else
      resize_to_fill(width,height)
    end
  end

  def resize_with_gravity(width, height, gravity = 'Center')
    manipulate! do |img|
      img.combine_options do |cmd|
        cmd.resize "#{width}"
        if img[:width] < img[:height]
          cmd.gravity gravity
          cmd.background "rgba(255,255,255,0.0)"
          cmd.extent "#{width}x#{height}"
        end
      end
      img = yield(img) if block_given?
      img
    end
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  # def extension_whitelist
  #   %w(jpg jpeg gif png)
  # end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end
end
