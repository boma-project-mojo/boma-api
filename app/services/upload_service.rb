class UploadService

	attr :s3_bucket

  # Initialize the service
	def initialize
		aws_credentials = Aws::Credentials.new(
		  ENV['S3_KEY'],
		  ENV['S3_SECRET']		  
		)

		@s3_bucket = Aws::S3::Resource.new(
		  region: ENV['S3_REGION'],
		  credentials: aws_credentials
		).bucket(ENV['S3_IMAGES_BUCKET_NAME'])

		return self
	end

  # Request a presigned URL to allow the admin section to upload a file directly to the s3.  
  # Params:
  # +filename+:: A string representing the filename to upload
  # +content_type+:: The content-type of the file to be uploaded
	def request_for_presigned_url filename, content_type
	  presigned_url = @s3_bucket.presigned_post(
	    key: "#{Rails.env}/#{SecureRandom.uuid}/#{filename.gsub(/[^0-9a-z\.]/i, '')}",
	    success_action_status: '201',
	    signature_expiration: (Time.now.utc + 15.minutes),
	    content_type: content_type
	  )

	  data = { url: presigned_url.url, url_fields: presigned_url.fields }
  end

  # Upload a file to the s3 bucket
  # Params:
  # +key+:: The name and path to upload the file to 
  # +file+:: The body of the file to be uploaded
  def upload_to_s3 key, file
    resp = @s3_bucket.put_object({
      acl: "public-read",
      cache_control: "max-age=30",
      body: file, 
      bucket: ENV['S3_IMAGES_BUCKET_NAME'], 
      key: key
    })

    return resp
  end

end