uri = URI.parse(ENV["couchdb_host"])
host = "#{uri.scheme}://#{ENV["couchdb_user"]}:#{ENV["couchdb_password"]}@#{uri.hostname}:#{uri.port}"
begin
  server = CouchRest.new(host, {timeout: 1000000, verify_ssl: false})
  ::CouchDB = server  
rescue Exception => e
  puts "could not initialize couchdb at #{}"
end