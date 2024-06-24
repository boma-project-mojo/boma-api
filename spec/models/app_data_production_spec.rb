require 'spec_helper'

describe AppData::Production do

  before(:all) do
    @organisation = Organisation.create! name: "Mock Org"
    @festival = Festival.new name: "Mock Festival", organisation_id: @organisation.id, timezone: "Europe/London", bundle_id: "com.com.com", schedule_modal_type: "production", start_date: DateTime.now-1.week, end_date: DateTime.now+1.week 
    @festival.remote_image_url = "https://boma-production-images.s3.amazonaws.com/test.png"
    @festival.save!

    @tag = AppData::Tag.create! name: "tag1", tag_type: "production", festival_id: @festival.id
    @venue = AppData::Venue.create! name: "venue1", venue_type: "performance", festival_id: @festival.id, remote_image_url: "https://boma-production-images.s3.amazonaws.com/test.png", description: "blah", list_order: 1
  end

  it "is valid with valid attributes" do
    @production = AppData::Production.new festival: @festival, name: "name", description: "description", remote_image_url: "https://boma-production-images.s3.amazonaws.com/test.png"
    @production.is_checking_app_validity = true
    expect(@production).to be_valid
  end

  describe "with invalid params" do
    # validates :name, :presence => {message: "can't be blank"}
    it "fails to create a new AppData::Production without a name" do
      @production = AppData::Production.new festival: @festival, description: "description", remote_image_url: "https://boma-production-images.s3.amazonaws.com/test.png"
      @production.is_checking_app_validity = true
      @production.valid?
      expect(@production.errors.count).to eq(1)
      expect(@production.errors['name'].to_sentence).to include("can't be blank")
    end

    # validates :short_description, :length => {maximum: 500, message: "can't be more than 250 characters"}
    it "fails to create a new AppData::Production with a short_description longer than 500 characters" do
      long_short_description = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec non dui laoreet, aliquet magna vel, tristique nibh. Mauris euismod bibendum lacinia. Cras a metus mauris. Nulla facilisi. Sed tempor metus ante, id faucibus sem accumsan accumsan. Vivamus consequat enim sagittis, feugiat massa ut, facilisis diam. Duis dapibus dui dui, a vehicula odio accumsan sit amet. Donec eget imperdiet enim. Duis hendrerit dui nisl, euismod finibus ante maximus sed. Ut eget eleifend diam, vitae vulputate pharetra."
      @production = AppData::Production.new festival: @festival, name: "name", short_description: long_short_description, description: "description", remote_image_url: "https://boma-production-images.s3.amazonaws.com/test.png"
      @production.is_checking_app_validity = true
      @production.valid?
      expect(@production.errors.count).to eq(1)
      expect(@production.errors['short_description'].to_sentence).to include("can't be more than 250 characters")
    end

    # validates :external_link, link: true, allow_blank: true
    # it's pretty much impossible to send an invalid url at the moment becuase of how it's setup
    it "fails to create a new AppData::Production with a link if the link is invalid" #do
    #   @production = AppData::Production.new festival: @festival, external_link: "blah", name: "name", description: "description", remote_image_url: "https://boma-production-images.s3.amazonaws.com/test.png"
    #   @production.is_checking_app_validity = true
    #   @production.valid?
    #   expect(@production.errors.count).to eq(1)
    #   expect(@production.errors['external_link'].to_sentence).to include("can't be invalid")
    # end

    # validate :has_image, if: -> {
    #   (is_checking_app_validity || 
    #   publishing? || 
    #   published?) && require_production_images? 
    # }
    it "succeeds in publishing an AppData::Production without a valid image when the image is not required" do
      @festival = Festival.new name: "Mock Festival", organisation_id: @organisation.id, timezone: "Europe/London", bundle_id: "com.com.com", schedule_modal_type: "production", start_date: DateTime.now-1.week, end_date: DateTime.now+1.week, require_production_images: false
      @festival.remote_image_url = "https://boma-production-images.s3.amazonaws.com/test.png"
      @festival.save!

      @production = AppData::Production.new festival: @festival, name: "name", description: "description"
      @production.is_checking_app_validity = true
      expect(@production).to be_valid
    end

    it "fails to publish an AppData::Production without a valid image" do
      @production = AppData::Production.new festival: @festival, external_link: "blah", name: "name", description: "description"
      @production.is_checking_app_validity = true
      @production.valid?
      expect(@production.errors.count).to eq(1)
      expect(@production.errors['image'].to_sentence).to include("must be added")
    end

    # validates :description, presence: {message: "can't be blank"}, if: -> {
    #   is_checking_app_validity || 
    #   publishing? || 
    #   published?
    # }
    it "fails to publish an AppData::Production without a valid description" do
      @production = AppData::Production.new festival: @festival, external_link: "blah", name: "name", remote_image_url: "https://boma-production-images.s3.amazonaws.com/test.png"
      @production.is_checking_app_validity = true
      @production.valid?
      expect(@production.errors.count).to eq(1)
      expect(@production.errors['description'].to_sentence).to include("can't be blank")
    end

    # validate :has_valid_events, if: -> {
    #   is_checking_app_validity || 
    #   publishing? || 
    #   published?
    # }
    it "fails to publish an AppData::Production with invalid events" do
      @production = AppData::Production.create! festival: @festival, name: "name", description: "description", remote_image_url: "https://boma-production-images.s3.amazonaws.com/test.png"
      @production.events.create! start_time: nil, end_time: nil, venue: @venue, festival: @festival, productions: [@production]
      @production.is_checking_app_validity = true
      @production.valid?
      expect(@production.errors.count).to eq(1)
      error = "Start time can't be blank and End time can't be blank (ID: #{@production.events.first.id})"
      expect(@production.errors['events'].to_sentence).to include(error)
    end
  end
end