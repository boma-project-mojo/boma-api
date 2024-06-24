require 'spec_helper'

describe DataApi::V1::TagsController do

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
      it "fails to create a new AppData::Tag without a name" do
        post :create, params: {
          tag_type: "performance",
          source_id: "1"
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "fails to create a new AppData::Tag without a festival_id or organisation_idr" do
        post :create, params: {
          name: "title", 
          tag_type: "performance",
          source_id: "1"
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "fails to create a new AppData::Tag without a tag_type" do
        post :create, params: {
          name: "title", 
          festival_id: @festival.id,
          source_id: "1"
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "fails to create a new AppData::Tag with a tag_type not in the controlled list" do
        post :create, params: {
          name: "title", 
          festival_id: @festival.id,
          tag_type: "sausages",
          source_id: "1"
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe "with valid params" do
      it "creates a new Tag in festival context" do
        expect {
          post :create, params: {
            name: "title", 
            festival_id: @festival.id,
            tag_type: "production",
            source_id: "1"
          }
        }.to change(@festival.tags, :count).by(1)

        expect(response).to have_http_status(:success)
      end

      it "creates a new Tag in organisation context" do
        expect {
          post :create, params: {
            name: "title2", 
            organisation_id: @organisation.id,
            tag_type: "production",
            source_id: "2"
          }
        }.to change(@organisation.tags, :count).by(1)

        expect(response).to have_http_status(:success)
      end
    end

    describe "in sandbox mode" do
      it "returns an error if the record is invalid" do
        expect {
          post :create, params: {
            name: "title3", 
            festival_id: @festival.id,
            tag_type: "production",
            sandbox: true
          }
        }.to change(@festival.tags, :count).by(0)

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "creates a new Tag in festival context without committing to the db" do
        expect {
          post :create, params: {
            name: "title3", 
            festival_id: @festival.id,
            tag_type: "production",
            source_id: "10",
            sandbox: true
          }
        }.to change(@festival.tags, :count).by(0)

        expect(response).to have_http_status(:success)
      end
    end
  end

end