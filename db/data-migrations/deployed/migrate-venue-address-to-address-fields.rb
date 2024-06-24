AppData::Venue.where.not(osm_id: nil).each {|v|
	json = JSON.parse(RestClient.get("https://nominatim.openstreetmap.org/lookup?osm_ids=W#{v.osm_id}&namedetails=1&addressdetails=1&format=geocodejson"))

	unless json['features'][0]
		json = JSON.parse(RestClient.get("https://nominatim.openstreetmap.org/lookup?osm_ids=N#{v.osm_id}&namedetails=1&addressdetails=1&format=geocodejson"))
	end

	unless json['features'][0]
		json = JSON.parse(RestClient.get("https://nominatim.openstreetmap.org/lookup?osm_ids=R#{v.osm_id}&namedetails=1&addressdetails=1&format=geocodejson"))
	end

	if json['features'][0]
		address_atts = {
			address_line_2: json['features'][0]['properties']['geocoding']['district'],
			postcode: json['features'][0]['properties']['geocoding']['postcode'],
			city: json['features'][0]['properties']['geocoding']['city']
		}

		if json['features'][0]['properties']['geocoding']['housenumber']
			address_atts[:address_line_1] = "#{json['features'][0]['properties']['geocoding']['housenumber']} #{json['features'][0]['properties']['geocoding']['street']}"
		else
			address_atts[:address_line_1] = json['features'][0]['properties']['geocoding']['street']
		end

		v.update! address_atts
	end
}