require 'spec_helper'

describe DataApi::V1::ProductionsController do

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

    @tag = AppData::Tag.create! name: "tag1", tag_type: "production", festival_id: @festival.id, source_id: '123'
  end

  before do 
    allow(controller).to receive(:authenticate_user!).and_return(true)
    allow(controller).to receive(:current_user).and_return(@user)
  end

  describe "POST create" do
    describe "with invalid params" do
      it "fails to create a new AppData::Production without a description" do
        post :create, params: {
          name: "name",
          festival_id: @festival.id,
          source_id: "123",
          image: "https://boma-production-images.s3.amazonaws.com/test.png"
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "fails to create a new AppData::Production without a festival_id" do
        post :create, params: {
          name: "name",
          description: "description",
          source_id: "123",
          image: "https://boma-production-images.s3.amazonaws.com/test.png"
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "fails to create a new AppData::Production without a source_id" do
        post :create, params: {
          name: "name",
          description: "description",
          festival_id: @festival.id,
          image: "https://boma-production-images.s3.amazonaws.com/test.png"
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "fails to create a new AppData::Production without an image" do
        post :create, params: {
          name: "name",
          description: "description",
          festival_id: @festival.id,
          source_id: "123"
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe "with valid params" do
      it "creates a new Production" do
        expect {
          post :create, params: {
            name: "Prod name", 
            description: "content", 
            image: "https://boma-production-images.s3.amazonaws.com/test.png",
            festival_id: @festival.id,
            source_id: "blah123",
            tag_source_ids: [@tag.source_id]
          }
        }.to change(@festival.productions, :count).by(1)

        expect(response).to have_http_status(:success)
      end

      it "creates a new Production with an external_link" do
        source_id = "blah1235"

        post :create, params: {
          name: "Prod name", 
          description: "content", 
          image: "https://boma-production-images.s3.amazonaws.com/test.png",
          festival_id: @festival.id,
          source_id: source_id,
          tag_source_ids: [@tag.source_id],
          external_link: "http://google.com"
        }

        expect(@festival.productions.find_by_source_id("blah1235").external_link).to eq("http://google.com")

        expect(response).to have_http_status(:success)
      end
    end

    describe "with sandbox enabled" do
      it "returns a success log without adding a record to the db" do
        expect {
          post :create, params: {
            name: "Prod name", 
            description: "content", 
            image: "https://boma-production-images.s3.amazonaws.com/test.png",
            festival_id: @festival.id,
            source_id: "1234",
            sandbox: true
          }
        }.to change(@festival.productions, :count).by(0)

        expect(response).to have_http_status(:success)
      end

      it "sends a unprocessable_entity response when sandbox is enabled" do
        expect {
          post :create, params: {
            name: "Prod name", 
            description: "content", 
            image: "https://boma-production-images.s3.amazonaws.com/test.png",
            festival_id: @festival.id,
            sandbox: true
          }
        }.to change(@festival.productions, :count).by(0)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

end