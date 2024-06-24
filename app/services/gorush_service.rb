# Go Rush Service
#
# This service provides the interface to send requests to GoRush servers to send push notifications.  

require 'httparty'

class GorushService
  # Make a request to the appropriate GoRush server for this Organisation.  
  # Params:
  # +payload+:: The payload to include in the request
  # +organisation_id+:: The organisation_id for the Organisation that has originated this request
	def self.send payload, organisation_id
		# Don't ever send messages when the server is running in development mode
    unless Rails.env.development?
			organisation = Organisation.find(organisation_id)

      # GoRush config is stored in the .env in the format GORUSH_API_ENDPOINT_{ORGANISATION_NAME}
      # Convert organisation name into appropriate param format
      org_name_parameterized = organisation.name.parameterize(separator: "_").upcase
      # Get appropriate config for this organisation
			endpoint = ENV["GORUSH_API_ENDPOINT_#{org_name_parameterized}"] ? ENV["GORUSH_API_ENDPOINT_#{org_name_parameterized}"] : ENV['GORUSH_API_ENDPOINT']
			username = ENV["GORUSH_USERNAME_#{org_name_parameterized}"] ? ENV["GORUSH_USERNAME_#{org_name_parameterized}"] : ENV['GORUSH_USERNAME']
			password = ENV["GORUSH_PASSWORD_#{org_name_parameterized}"] ? ENV["GORUSH_PASSWORD_#{org_name_parameterized}"] : ENV['GORUSH_PASSWORD']
      
      # Create auth payload
			auth = {:username => username, :password => password}
      # Make the request
			res = HTTParty.post("#{endpoint}/api/push", 
				body: payload.to_json, headers: { 'Content-Type' => 'application/json' },
				basic_auth: auth
			)
			if res["success"] === "ok"
				puts res
				return true;
			else
				raise Exception.new(res.response)
			end
		else
			raise "Don't ever send messages to the GoRush servers in development mode"
		end
	end
end