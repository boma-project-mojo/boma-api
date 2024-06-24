require 'spec_helper'

describe DataApi::V1::VenuesController do

  before(:all) do
    @organisation = Organisation.create! name: "Mock Org"
    @festival = Festival.new name: "Mock Festival", organisation_id: @organisation.id, timezone: "Europe/London", bundle_id: "com.com.com", schedule_modal_type: "production", start_date: DateTime.now-1.week, end_date: DateTime.now+1.week 
    @festival.remote_image_url = "https://boma-production-images.s3.amazonaws.com/test.png"
    @festival.save!
    
    @user = User.where({
      name: 'test',
      email: 'one@two.co.uk',
    }).first_or_initialize

    @user.password = 'abcdefgh'
    @user.password_confirmation = 'abcdefgh'

    @user.save!

    @user.add_role(:api_write, @organisation)
    @user.add_role(:api_write, @festival)
  end

  before do 
    allow(controller).to receive(:authenticate_user!).and_return(true)
    allow(controller).to receive(:current_user).and_return(@user)
  end

  describe "POST create" do
    describe "with invalid params" do
      it "fails to create a new AppData::Venue without a description" do
        post :create, params: {
          name: "Venue name",
          venue_type: "performance",
          festival_id: @festival.id,
          image: "https://boma-production-images.s3.amazonaws.com/test.png",
          source_id: "1",
          list_order: 1
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "fails to create a new AppData::Venue without an image" do
        post :create, params: {
          name: "Venue name",
          venue_type: "performance",
          description: "Venue Description",
          festival_id: @festival.id,
          source_id: "1",
          list_order: 1
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "fails to create a new AppData::Venue without a festival_id" do
        post :create, params: {
          name: "Venue name", 
          description: "content", 
          venue_type: "performance",
          image: "https://boma-production-images.s3.amazonaws.com/test.png",
          source_id: "1",
          list_order: 1
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "fails to create a new AppData::Venue for a venue_type not included in the controlled list" do
        post :create, params: {
          name: "Venue name", 
          description: "content", 
          venue_type: "blah",
          image: "https://boma-production-images.s3.amazonaws.com/test.png",
          festival_id: @festival.id,
          source_id: "1",
          list_order: 1
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe "venue with valid params" do
      it "creates a new Venue" do
        expect {
          post :create, params: {
            name: "Venue name", 
            description: "content", 
            venue_type: "performance",
            image: "https://boma-production-images.s3.amazonaws.com/test.png",
            festival_id: @festival.id,
            source_id: "1234",
            list_order: 1
          }
        }.to change(@festival.venues, :count).by(1)

        expect(response).to have_http_status(:success)
      end
    end

    describe "with sandbox enabled" do
      it "returns a success log without adding a record to the db" do
        expect {
          post :create, params: {
            name: "Venue name", 
            description: "content", 
            venue_type: "performance",
            image: "https://boma-production-images.s3.amazonaws.com/test.png",
            festival_id: @festival.id,
            source_id: "12345",
            sandbox: true,
            list_order: 1
          }
        }.to change(@festival.venues, :count).by(0)

        expect(response).to have_http_status(:success)
      end

      it "sends a unprocessable_entity response when sandbox is enabled" do
        expect {
          post :create, params: {
            name: "Venue name", 
            description: "content", 
            venue_type: "performance",
            image: "https://boma-production-images.s3.amazonaws.com/test.png",
            festival_id: @festival.id,
            sandbox: true,
            list_order: 1
          }
        }.to change(@festival.venues, :count).by(0)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

end