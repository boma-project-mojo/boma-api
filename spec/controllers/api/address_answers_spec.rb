require 'spec_helper'

describe Api::V1::AddressAnswersController do

  before(:all) do
    @organisation = Organisation.create! name: "Mock Org"
    @festival = Festival.new name: "Mock Festival", organisation_id: @organisation.id, timezone: "Europe/London", bundle_id: "com.com.com", schedule_modal_type: "production", start_date: DateTime.now-1.week, end_date: DateTime.now+1.week 
    @festival.remote_image_url = "https://boma-production-images.s3.amazonaws.com/test.png"
    @festival.save!

    @article = AppData::Article.new article_type: :boma_news_article, title: "Mock Artilce", organisation_id: @organisation.id, content: "Mock Content" 
    @article.remote_image_url = "https://boma-production-images.s3.amazonaws.com/test.png"
    @article.save!

    @survey = AppData::Survey.create! surveyable_id: @article.id, surveyable_type: "AppData::Article"
    @question1 = AppData::Question.create! survey_id: @survey.id, question_text: "Test Question", question_type: "multiple_choice"
    @answer1 = AppData::Answer.create! question_id: @question1.id, answer_text: "Test Answer 1"
    @answer2 = AppData::Answer.create! question_id: @question1.id, answer_text: "Test Answer 2"

    key = Eth::Key.new
    @address = Address.create! address: key.address  
  end

  before do 
    allow(controller).to receive(:authenticate_user!).and_return(true)
    allow(controller).to receive(:current_user).and_return(@user)
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new AppData::AddressAnswer for the relevant result" do
        request_payload = {
          address: @address.address,
          survey_id: @survey.id,
          question_id: @question1.id,
          answer_id: @answer1.id
        }

        post :create, params: request_payload

        expect(response).to have_http_status(:success)
      end

      it "can't answer the same question twice" do
        @address.address_answers.create! question_id: @question1.id, answer_id: @answer1.id

        request_payload = {
          address: @address.address,
          question_id: @question1.id,
          answer_id: @answer1.id
        }

        post :create, params: request_payload

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "can answer the survey at any time if enable_at and disable_at are nil" do
        request_payload = {
          address: @address.address,
          question_id: @question1.id,
          answer_id: @answer1.id
        }

        post :create, params: request_payload

        expect(response).to have_http_status(:success)
      end

      it "can't answer before the survey is enabled" do
        @survey.update! enable_at: DateTime.now+1.week, disable_at: DateTime.now+2.weeks

        request_payload = {
          address: @address.address,
          question_id: @question1.id,
          answer_id: @answer1.id
        }

        post :create, params: request_payload

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "can't answer the survey after the survey is disabled" do
        @survey.update! enable_at: DateTime.now-2.weeks, disable_at: DateTime.now-1.weeks

        request_payload = {
          address: @address.address,
          question_id: @question1.id,
          answer_id: @answer1.id
        }

        post :create, params: request_payload

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "can answer the survey if it's enabled" do
        @survey.update! enable_at: DateTime.now-2.weeks, disable_at: DateTime.now+1.weeks

        request_payload = {
          address: @address.address,
          question_id: @question1.id,
          answer_id: @answer1.id
        }

        post :create, params: request_payload

        expect(response).to have_http_status(:success)
      end
    end
  end

end