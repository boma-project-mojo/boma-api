module ImageUploadConcern
  extend ActiveSupport::Concern

    def convert_to_upload(image)
      if image[:name] === "" or image[:name].nil?
        image[:name] = "#{SHA3::Digest::SHA256.new(DateTime.now.to_s).to_s[0..7]}.jpg"
      end

      image_data = split_base64(image[:data])

      temp_img_file = Tempfile.new("data_uri-upload")
      temp_img_file.binmode
      temp_img_file << Base64.decode64(image_data[:data])
      temp_img_file.rewind

      ActionDispatch::Http::UploadedFile.new({
        filename: image[:name],
        type: image[:type],
        tempfile: temp_img_file
      })
    end

    def split_base64(uri_str)
      if uri_str.match(%r{^data:(.*?);(.*?),(.*)$})
        uri = Hash.new
        uri[:type] = $1 # "image/gif"
        uri[:encoder] = $2 # "base64"
        uri[:data] = $3 # data string
        uri[:extension] = $1.split('/')[1] # "gif"
        return uri
      end
    end

end