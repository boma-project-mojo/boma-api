require 'spec_helper'

describe Api::V1::ActivitiesController do

  before(:all) do
    @organisation = Organisation.create! name: "Mock Org"
    @festival = Festival.new name: "Mock Festival", organisation_id: @organisation.id, timezone: "Europe/London", bundle_id: "com.com.com", schedule_modal_type: "production", start_date: DateTime.now-1.week, end_date: DateTime.now+1.week 
    @festival.remote_image_url = "https://boma-production-images.s3.amazonaws.com/test.png"
    @festival.save!

    @festival2 = Festival.new name: "Mock Festival 2", organisation_id: @organisation.id, timezone: "Europe/London", bundle_id: "com.com.com", schedule_modal_type: "production", start_date: DateTime.now-1.week, end_date: DateTime.now+1.week 
    @festival2.remote_image_url = "https://boma-production-images.s3.amazonaws.com/test.png"
    @festival2.save!

    @article = AppData::Article.new article_type: :boma_news_article, title: "Mock Artilce", organisation_id: @organisation.id, content: "Mock Content" 
    @article.remote_image_url = "https://boma-production-images.s3.amazonaws.com/test.png"
    @article.save!

    key = Eth::Key.new
    @address = Address.create! address: key.address  

    key2 = Eth::Key.new
    @address2 = Address.new address: key2.address
  end

  before do 
    allow(controller).to receive(:authenticate_user!).and_return(true)
    allow(controller).to receive(:current_user).and_return(@user)
  end

  describe "POST report_activity" do
    describe "with valid params" do
      it "successfully creates a Activity for this address" do
        request_payload = {
          address: @address.address,
          app_version: "shambala-2023-50.0.8+451a22c2",
          activity_type: "app_usage",
          reported_data: '{"ping":{"total_all":2},"love":{"event":{"total":6,"event_type":{"boma_event":6},"tags":{"662":1,"663":4,"666":2}},"article":{"total":4,"article_type":{"boma_article":4},"tags":{}}}}',
          timezone: "Europe/London",
          organisation_id: @organisation.id,
          festival_id: @festival.id
        }

        expect { post :report_activity, params: request_payload }.to change(Activity, :count).by(1) 
        expect(response).to have_http_status(:success)
      end

      it "successfully updates an app_usage Activity for this address" do
        request_payload = {
          address: @address.address,
          app_version: "shambala-2023-50.0.8+451a22c2",
          activity_type: "app_usage",
          reported_data: '{"ping":{"total_all":2},"love":{"event":{"total":6,"event_type":{"boma_event":6},"tags":{"662":1,"663":4,"666":2}},"article":{"total":4,"article_type":{"boma_article":4},"tags":{}}}}',
          timezone: "Europe/London",
          organisation_id: @organisation.id,
          festival_id: @festival.id
        }

        # Create the Activity object that will be updated.
        post :report_activity, params: request_payload

        expect { post :report_activity, params: request_payload }.to change(Activity, :count).by(0) 
        expect(response).to have_http_status(:success)
      end
    end

    describe "with invalid params" do
      it "doesn't create a Activity if address doesn't exist" do
        request_payload = {
          address: "address-that-doesn't-exist",
          app_version: "shambala-2023-50.0.8+451a22c2",
          activity_type: "app_usage",
          reported_data: '{"ping":{"total_all":2},"love":{"event":{"total":6,"event_type":{"boma_event":6},"tags":{"662":1,"663":4,"666":2}},"article":{"total":4,"article_type":{"boma_article":4},"tags":{}}}}',
          timezone: "Europe/London",
          organisation_id: @organisation.id,
          festival_id: @festival.id
        }

        expect { post :report_activity, params: request_payload }.to change(Activity, :count).by(0) 
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "POST report_activity_for_all_festivals" do
    describe "with valid params" do
      it "successfully creates a Activity for each of the festivals for this address" do
        request_payload = {
          address: @address.address,
          app_version: "shambala-2023-50.0.8+451a22c2",
          activity_type: "app_usage",
          activities: { 
            "0": {
              festival_id: @festival.id,
              reported_data: '{"ping":{"total_all":2},"love":{"event":{"total":6,"event_type":{"boma_event":6},"tags":{"662":1,"663":4,"666":2}},"article":{"total":4,"article_type":{"boma_article":4},"tags":{}}}}',
            },
            "1": {
              festival_id: @festival2.id,
              reported_data: '{"ping":{"total_all":2},"love":{"event":{"total":6,"event_type":{"boma_event":6},"tags":{"662":1,"663":4,"666":2}},"article":{"total":4,"article_type":{"boma_article":4},"tags":{}}}}',
            }
          },
          timezone: "Europe/London",
          organisation_id: @organisation.id,
        }

        expect { post :report_activity_for_all_festivals, params: request_payload }.to change(Activity, :count).by(2) 
        expect(response).to have_http_status(:success)
      end
    end

    describe "with invalid params" do
      it "invalid activity isn't created" do
        request_payload = {
          address: @address.address,
          app_version: "shambala-2023-50.0.8+451a22c2",
          activity_type: "app_usage",
          activities: {
            "0": {
              festival_id: @festival.id,
              reported_data: '{"ping":{"total_all":2},"love":{"event":{"total":6,"event_type":{"boma_event":6},"tags":{"662":1,"663":4,"666":2}},"article":{"total":4,"article_type":{"boma_article":4},"tags":{}}}}',
            },
            "1": {
              festival_id: nil,
              reported_data: nil,
            }
          },
          timezone: "Europe/London",
          organisation_id: @organisation.id,
        }

        expect { post :report_activity_for_all_festivals, params: request_payload }.to change(Activity, :count).by(0) 
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

end