require 'spec_helper'

describe Api::V1::SurveysController do

  before(:all) do
    @organisation = Organisation.create! name: "Mock Org"
    @festival = Festival.new name: "Mock Festival", organisation_id: @organisation.id, timezone: "Europe/London", bundle_id: "com.com.com", schedule_modal_type: "production", start_date: DateTime.now-1.week, end_date: DateTime.now+1.week 
    @festival.remote_image_url = "https://boma-production-images.s3.amazonaws.com/test.png"
    @festival.save!

    @article = AppData::Article.new article_type: :boma_news_article, title: "Mock Artilce", organisation_id: @organisation.id, content: "Mock Content" 
    @article.remote_image_url = "https://boma-production-images.s3.amazonaws.com/test.png"
    @article.save!

    @survey = AppData::Survey.create! surveyable_id: @article.id, surveyable_type: "AppData::Article"
    @question1 = AppData::Question.create! survey_id: @survey.id, question_text: "Test Question", question_type: "single_choice"
    @answer1 = AppData::Answer.create! question_id: @question1.id, answer_text: "Test Answer 1"
    @answer2 = AppData::Answer.create! question_id: @question1.id, answer_text: "Test Answer 2"

    @question2 = AppData::Question.create! survey_id: @survey.id, question_text: "Test Question 2", question_type: "single_choice"
    @q2answer1 = AppData::Answer.create! question_id: @question2.id, answer_text: "q2 Test Answer 1"
    @q2answer2 = AppData::Answer.create! question_id: @question2.id, answer_text: "q2 Test Answer 2"
    
    key = Eth::Key.new
    @address = Address.create! address: key.address  

    key2 = Eth::Key.new
    @address2 = Address.new address: key2.address
  end

  before do 
    allow(controller).to receive(:authenticate_user!).and_return(true)
    allow(controller).to receive(:current_user).and_return(@user)
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new AppData::AddressAnswer for each question if valid" do
        request_payload = {
          address: @address.address,
          survey_id: @survey.id,
          questions: {
            "0": {
              id: @question1.id,
              answer_id: @answer1.id
            },
            "1": {
              id: @question2.id,
              answer_id: @answer2.id
            },
          }
        }

        expect { post :create, params: request_payload }.to change(AppData::AddressAnswer, :count).by(2) 
        expect(response).to have_http_status(:success)
      end

      it "returns a 422 and doens't create any new records if any one is invalid" do
        request_payload = {
          address: @address.address,
          survey_id: @survey.id,
          questions: {
            "0": {
              id: @question1.id,
              answer_id: @answer1.id
            },
            "1": {
              id: @question2.id,
              answer_id: 1000
            },
          }
        }

        expect { post :create, params: request_payload }.to change(AppData::AddressAnswer, :count).by(0) 
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "when Address doesn't exist (user has opted out of push notifications) it returns a 200, creates an Address and creates a new AppData::AddressAnswer for each question " do
        request_payload = {
          address: @address2.address,
          survey_id: @survey.id,
          questions: {
            "0": {
              id: @question1.id,
              answer_id: @answer1.id
            },
            "1": {
              id: @question2.id,
              answer_id: @answer2.id
            },
          }
        }

        expect { post :create, params: request_payload }.to change(AppData::AddressAnswer, :count).by(2) 
        expect(response).to have_http_status(:success)
      end
    end
  end

end