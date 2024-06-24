#Simulate poor network requests using toxiproxy

`toxiproxy-cli create rails -l 127.0.0.1:3001 -u localhost:3000`

(crucial to remember here that rails doesn't bind to 127.0.0.1 unless you run the server with -p 127.0.0.1 hence the above command including `localhost` rather than 127.0.0.1 for upstream)

## simulate latency

`toxiproxy-cli toxic add rails -t latency -a latency=10000`