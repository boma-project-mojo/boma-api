require 'spec_helper'

describe DataApi::V1::ArticlesController do

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
      it "fails to create a new AppData::Article without an image" do
        post :create, params: {
          title: "title", 
          content: "content", 
          festival_id: @festival.id,
          source_id: "1"
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "fails to create a new AppData::Article without a festival_id or organisation_idr" do
        post :create, params: {
          title: "title", 
          content: "content", 
          image: "https://boma-production-images.s3.amazonaws.com/test.png",
          source_id: "1"
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe "article with valid params" do
      it "creates a new Article in the organisation context" do
        expect {
          post :create, params: {
            title: "title", 
            content: "content", 
            image: "https://boma-production-images.s3.amazonaws.com/test.png",
            organisation_id: @organisation.id,
            source_id: "1",
            article_type: "boma_news_article"
          }
        }.to change(@organisation.articles, :count).by(1)

        expect(response).to have_http_status(:success)
      end

      it "creates a new Article in the festival context" do
        expect {
          post :create, params: {
            title: "title", 
            content: "content", 
            image: "https://boma-production-images.s3.amazonaws.com/test.png",
            festival_id: @festival.id,
            source_id: "2",
            article_type: "boma_news_article"
          }
        }.to change(@festival.articles, :count).by(1)

        expect(response).to have_http_status(:success)
      end

      it "updates an Article in the festival context" do
        post :create, params: {
          title: "title", 
          content: "content", 
          image: "https://boma-production-images.s3.amazonaws.com/test.png",
          festival_id: @festival.id,
          article_type: "boma_news_article",
          source_id: "3"
        }

        article = post :create, params: {
          title: "title changed", 
          source_id: "3",
          festival_id: @festival.id
        }

        expect(@festival.articles.find_by_source_id("3").title).to eq("title changed")
        expect(response).to have_http_status(:success)
      end
    end

    describe "with sandbox enabled" do
      it "returns a success log without adding a record to the db" do
        expect {
          post :create, params: {
            title: "title", 
            content: "content", 
            image: "https://boma-production-images.s3.amazonaws.com/test.png",
            organisation_id: @organisation.id,
            source_id: "3",
            sandbox: true,
            article_type: "boma_news_article"
          }
        }.to change(@organisation.articles, :count).by(0)

        expect(response).to have_http_status(:success)
      end

      it "sends a unprocessable_entity response when sandbox is enabled" do
        expect {
          post :create, params: {
            title: "title", 
            content: "content", 
            image: "https://boma-production-images.s3.amazonaws.com/test.png",
            festival_id: @festival.id,
          }
        }.to change(@festival.articles, :count).by(0)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

end