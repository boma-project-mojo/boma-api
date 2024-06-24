class Api::V1::VenuesController < ApplicationController
  skip_before_action :verify_authenticity_token, :authenticate_user!

  def create
    raise "This is not a community venue" if venue_params[:venue_type] != "community_venue"

    # Check there's a wallet
    if venue_params[:wallet_address] 
      # Check that there's a valid token for this wallet
      # if Token.where(address: venue_params[:wallet_address]).count > 0
        @venue = AppData::Venue.find_or_initialize_by(
          name: venue_params[:name], 
          lat: venue_params[:lat], 
          long: venue_params[:long],
          venue_type: venue_params[:venue_type],
          festival_id: venue_params[:festival_id],
          address: venue_params[:address],
          address_line_1: venue_params[:address_line_1],
          address_line_2: venue_params[:address_line_2],
          city: venue_params[:city],
          postcode: venue_params[:postcode],
          osm_id: venue_params[:osm_id],
          wallet_address: venue_params[:wallet_address]
        )

        if @venue.save
          render json: {success: true, venue: @venue}
        else
          render json: {errors: format_error(@venue.errors)}, status: :unprocessable_entity
        end
      # else
      #   errors = ["You must have a valid token to submit events."]
      #   render json: {errors: {base: errors}} , status: :unprocessable_entity
      # end
    else
      errors = ["You must have a valid wallet to submit events."]
      render json: {errors: {base: errors}} , status: :unprocessable_entity
    end
  end

  def search
    unless search_params[:q].nil? or search_params[:q].empty?
      ar_venues = AppData::Venue.where(venue_type: 'community_venue').where('name ILIKE ?', "%#{search_params[:q]}%")
    end

    exclude_osm_ids = ar_venues.collect(&:osm_id)
    nominatim_response = RestClient.get("#{ENV['NOMINATIM_URL']}/search?q=#{search_params[:q]}&exclude_place_ids=#{exclude_osm_ids}&format=geocodejson&namedetails=1&addressdetails=1")
    nominatim_venues = JSON.parse(nominatim_response)

    puts "#{ENV['NOMINATIM_URL']}/search?q=#{search_params[:q]}&exclude_place_ids=#{exclude_osm_ids}&format=geocodejson&namedetails=1&addressdetails=1"

    @venues = []

    ar_venues.each do |v|
      city = v.city rescue nil

      @venues << {
        id: v.id,
        name: v.name,
        display_name: v.full_address,
        lat: v.lat,
        lon: v.long,
        address_line_1: v.address_line_1,
        address_line_2: v.address_line_2,
        postcode: v.postcode,
        address: v.full_address,
        osm_id: v.osm_id,
        city: city
      }
    end


    nominatim_venues["features"].each do |ven|
      if ven['properties']['geocoding']['housenumber']
        address_line_1 = "#{ven['properties']['geocoding']['housenumber']} #{ven['properties']['geocoding']['street']}"
      else
        address_line_1 = ven['properties']['geocoding']['street']
      end

      venue_obj = {
        name: ven["properties"]["geocoding"]["name"],
        lat: ven["geometry"]["coordinates"][1],
        lon: ven["geometry"]["coordinates"][0],
        osm_id: ven["properties"]["geocoding"]["osm_id"],
        address_line_1: address_line_1,
        address_line_2: ven["properties"]["geocoding"]["district"],
        city: ven["properties"]["geocoding"]["city"],
        postcode: ven["properties"]["geocoding"]["postcode"],
      }

      sane_address_string = sane_address_string(venue_obj)

      venue_obj["display_name"] = sane_address_string
      venue_obj["address"] = sane_address_string

      @venues << venue_obj
    end

    render json: @venues.to_json
  end

  def reverse_search
    nominatim_response = RestClient.get("#{ENV['NOMINATIM_URL']}/reverse?lat=#{reverse_search_params[:lat]}&lon=#{reverse_search_params[:lon]}&format=json&namedetails=1")
    render json: nominatim_response
  end

  private
    # # Never trust parameters from the scary internet, only allow the white list through.
    def venue_params
      params[:address] = sane_address_string(params)
      params.permit([:name, :lat, :long, :venue_type, :festival_id, :osm_id, :wallet_address, :city, :address_line_1, :address_line_2, :postcode, :address])  
    end

    def search_params
      params.permit(:q)
    end

    def reverse_search_params
      params.permit(:lat, :lon)
    end

    def sane_address_string venue_obj
      sane_address_string = ""
      sane_address_string += "#{venue_obj[:name]}, " unless venue_obj[:name].blank?
      sane_address_string += "#{venue_obj[:address_line_1]}, " if venue_obj[:address_line_1]
      sane_address_string += "#{venue_obj[:address_line_2]}, " unless venue_obj[:address_line_2].blank?
      sane_address_string += "#{venue_obj[:city]}, " unless venue_obj[:city].blank?
      sane_address_string += "#{venue_obj[:postcode]}" unless venue_obj[:postcode].blank?
    end
end