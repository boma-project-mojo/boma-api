require 'spec_helper'

describe DataApi::V1::EventsController do

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

    p_params = {
      name: "Prod name", 
      description: "content", 
      festival_id: @festival.id,
      source_id: "123"
    }
    @production = AppData::Production.new p_params
    @production.remote_image_url = "https://boma-production-images.s3.amazonaws.com/test.png"
    @production.save!  

    p2_params = {
      name: "Prod name 2", 
      description: "content", 
      festival_id: @festival.id,
      source_id: "124"
    }
    @production2 = AppData::Production.new p2_params
    @production2.remote_image_url = "https://boma-production-images.s3.amazonaws.com/test.png"
    @production2.save!  

    v_params = {
      name: "Venue name", 
      description: "content", 
      venue_type: "performance",
      image: "https://boma-production-images.s3.amazonaws.com/test.png",
      festival_id: @festival.id,
      source_id: "123",
      list_order: 1
    }
    @venue = AppData::Venue.new v_params
    @venue.remote_image_url = "https://boma-production-images.s3.amazonaws.com/test.png"
    @venue.save!
  end

  before do 
    allow(controller).to receive(:authenticate_user!).and_return(true)
    allow(controller).to receive(:current_user).and_return(@user)
  end

  describe "POST create" do
    describe "with invalid params" do
      it "fails to create a new AppData::Event without productions" do
        post :create, params: {
          festival_id: @festival.id,
          start_time: DateTime.now,
          end_time: DateTime.now+1.hour,
          venue_source_id: @venue.source_id,
          source_id: "1",
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "fails to create a new AppData::Event without festival_id" do
        post :create, params: {
          start_time: DateTime.now,
          end_time: DateTime.now+1.hour,
          venue_source_id: @venue.source_id,
          source_id: "1",
          production_source_ids: [@production.source_id]
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "fails to create a new AppData::Event without start_time" do
        post :create, params: {
          festival_id: @festival.id,
          end_time: DateTime.now+1.hour,
          venue_source_id: @venue.source_id,
          source_id: "1",
          production_source_ids: [@production.source_id]
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "fails to create a new AppData::Event without end_time" do
        post :create, params: {
          festival_id: @festival.id,
          start_time: DateTime.now,
          venue_source_id: @venue.source_id,
          source_id: "1",
          production_source_ids: [@production.source_id]
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "fails to create a new AppData::Event without venue" do
        post :create, params: {
          festival_id: @festival.id,
          start_time: DateTime.now,
          end_time: DateTime.now+1.hour,
          source_id: "1",
          production_source_ids: [@production.source_id]
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "fails to create a new AppData::Event without source_id" do
        post :create, params: {
          festival_id: @festival.id,
          start_time: DateTime.now,
          end_time: DateTime.now+1.hour,
          venue_source_id: @venue.source_id,
          production_source_ids: [@production.source_id]
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe "with valid params" do
      it "creates a new Event" do
        expect {
          post :create, params: {
            festival_id: @festival.id,
            start_time: DateTime.now,
            end_time: DateTime.now+1.hour,
            venue_source_id: @venue.source_id,
            source_id: "1",
            production_source_ids: [@production.source_id]
          }
        }.to change(@festival.events, :count).by(1)
        
        expect(response).to have_http_status(:success)
      end

      it "updates an Event and changes the production" do
        post :create, params: {
          festival_id: @festival.id,
          start_time: DateTime.now,
          end_time: DateTime.now+1.hour,
          venue_source_id: @venue.source_id,
          source_id: "1",
          production_source_ids: [@production.source_id]
        }

        event = post :create, params: {
          festival_id: @festival.id,
          start_time: DateTime.now,
          end_time: DateTime.now+1.hour,
          venue_source_id: @venue.source_id,
          source_id: "1",
          production_source_ids: [@production2.source_id]
        }

        expect(@festival.events.find_by_source_id("1").productions.count).to eq(1)
        expect(@festival.events.find_by_source_id("1").productions.first.source_id).to eq("124")
        expect(response).to have_http_status(:success)
      end
    end

    describe "with sandbox enabled" do
      it "returns a success log without adding a record to the db" do
        expect {
          post :create, params: {
            festival_id: @festival.id,
            start_time: DateTime.now,
            end_time: DateTime.now+1.hour,
            venue_source_id: @venue.source_id,
            source_id: "10",
            production_source_ids: [@production.source_id],
            sandbox: true
          }
        }.to change(@festival.events, :count).by(0)

        expect(response).to have_http_status(:success)
      end

      it "sends a unprocessable_entity response when sandbox is enabled" do
        expect {
          post :create, params: {
            festival_id: @festival.id,
            start_time: DateTime.now,
            end_time: DateTime.now+1.hour,
            production_source_ids: [@production.source_id],
            sandbox: true
          }
        }.to change(@festival.events, :count).by(0)
      end
    end
  end

end