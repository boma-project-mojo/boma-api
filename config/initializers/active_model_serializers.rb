ActiveModelSerializers.config.adapter = :json_api # Default: `:attributes`§

ActiveModelSerializers.config.key_transform = :underscore

api_mime_types = %W(
  application/vnd.api+json
  text/x-json
  application/json
)

Mime::Type.unregister :json
Mime::Type.register 'application/json', :json, api_mime_types