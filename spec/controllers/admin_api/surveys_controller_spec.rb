require 'spec_helper'

describe AdminApi::V1::SurveysController do

  before(:all) do
    @organisation = Organisation.create! name: "Mock Org"
    @festival = Festival.new name: "Mock Festival", organisation_id: @organisation.id, timezone: "Europe/London", bundle_id: "com.com.com", schedule_modal_type: "production", start_date: DateTime.now-1.week, end_date: DateTime.now+1.week 
    @festival.remote_image_url = "https://boma-production-images.s3.amazonaws.com/test.png"
    @festival.save!

    @article = AppData::Article.new article_type: :boma_news_article, title: "Mock Artilce", organisation_id: @organisation.id, content: "Mock Content" 
    @article.remote_image_url = "https://boma-production-images.s3.amazonaws.com/test.png"
    @article.save!

    @user = User.where({
      name: 'test',
      email: 'one@two.co.uk',
    }).first_or_initialize

    @user.password = 'abcdefgh'
    @user.password_confirmation = 'abcdefgh'

    @user.save!
    @user.add_role(:super_admin)
  end

  before do 
    allow(controller).to receive(:authenticate_user!).and_return(true)
    allow(controller).to receive(:current_user).and_return(@user)
  end

  describe "GET show" do
    it "shows the results of a survey" do
      @organisation = Organisation.create! name: "Mock Org"
      @article = AppData::Article.new article_type: :boma_news_article, title: "Mock Artilce", organisation_id: @organisation.id, content: "Mock Content" 
      @article.remote_image_url = "https://boma-production-images.s3.amazonaws.com/test.png"
      @article.save!

      @survey = AppData::Survey.create! surveyable_id: @article.id, surveyable_type: "AppData::Article"
      @question1 = AppData::Question.create! survey_id: @survey.id, question_text: "Test Question", question_type: "multiple_choice"
      @answer1 = AppData::Answer.create! question_id: @question1.id, answer_text: "Test Answer 1"
      @answer2 = AppData::Answer.create! question_id: @question1.id, answer_text: "Test Answer 2"
      key = Eth::Key.new
      @address = Address.create! address: key.address  
      @address_answer1 = AppData::AddressAnswer.create! question_id: @question1.id, answer_id: @answer1.id, address_id: @address.id
      
      key = Eth::Key.new
      @address2 = Address.create! address: key.address  
      @address_answer2 = AppData::AddressAnswer.new question_id: @question1.id, answer_id: @address2.id, address_id: @address.id
    
      request_payload = {
        festival_id: @festival.id,
        id: @survey.id
      }

      get :show, params: request_payload

      expect(response).to have_http_status(:success)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new AppData::Survey with related questions and answers related to an article" do
        request_payload = {
          data: {
            attributes: {
              article_id: @article.id
            }, 
            relationships: {
              questions: {
                data: [
                  { 
                    question_text: "Question Text 1", 
                    question_type: "single_choice",
                    answers_attributes: [
                      { answer_text: "Answer Text 1"},
                      { answer_text: "Answer Text 2"},
                      { answer_text: "Answer Text 3"}
                    ],
                  },
                  { 
                    question_text: "Question Text 2", 
                    question_type: "single_choice",
                    answers_attributes: [
                      { answer_text: "Answer Text 1"},
                      { answer_text: "Answer Text 2"},
                      { answer_text: "Answer Text 3"}
                    ]
                  },
                  { 
                    question_text: "Question Text 3", 
                    question_type: "single_choice",
                    answers_attributes: [
                      { answer_text: "Answer Text 1"},
                      { answer_text: "Answer Text 2"},
                      { answer_text: "Answer Text 3"}
                    ]
                  }
                ]
              },
            },
            type: "surveys"
          }, 
          controller: "admin_api/v1/surveys",
          action: "create"
        }

        post :create, params: request_payload

        expect(response).to have_http_status(:success)
      end

      it "creates a new AppData::Survey with related questions and answers related to an article" do
        request_payload = {
          data: {
            attributes: {
              article_id: @article.id
            }, 
            relationships: {
              questions: {
                data: [
                  { 
                    question_text: "Question Text 1", 
                    question_type: "single_choice",
                    answers_attributes: [
                      { answer_text: "Answer Text 1"},
                      { answer_text: "Answer Text 2"},
                      { answer_text: "Answer Text 3"}
                    ],
                  },
                  { 
                    question_text: "Question Text 2", 
                    question_type: "single_choice",
                    answers_attributes: [
                      { answer_text: "Answer Text 1"},
                      { answer_text: "Answer Text 2"},
                      { answer_text: "Answer Text 3"}
                    ]
                  },
                  { 
                    question_text: "Question Text 3", 
                    question_type: "single_choice",
                    answers_attributes: [
                      { answer_text: "Answer Text 1"},
                      { answer_text: "Answer Text 2"},
                      { answer_text: "Answer Text 3"}
                    ]
                  }
                ]
              },
            },
            type: "surveys"
          }, 
          controller: "admin_api/v1/surveys",
          action: "create"
        }

        post :create, params: request_payload

        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "POST update" do
    it "updates a survey" do 
      @survey = AppData::Survey.create! surveyable_id: @article.id, surveyable_type: "AppData::Article"
      @question1 = AppData::Question.create! survey_id: @survey.id, question_text: "Test Question", question_type: "multiple_choice"
      @answer1 = AppData::Answer.create! question_id: @question1.id, answer_text: "Test Answer 1"
      @answer2 = AppData::Answer.create! question_id: @question1.id, answer_text: "Test Answer 2"

      @article2 = AppData::Article.new article_type: :boma_news_article, title: "Mock Artilce", organisation_id: @organisation.id, content: "Mock Content" 
      @article2.remote_image_url = "https://boma-production-images.s3.amazonaws.com/test.png"
      @article2.save!      

      request_payload = {
        organisation_id: @organisation.id,
        id: @survey.id,
        data: {
          attributes: {
            article_id: @article2.id
          }, 
          relationships: {},
          type: "surveys"
        }, 
      }

      put :update, params: request_payload

      expect(AppData::Survey.find(@survey.id).surveyable_id).to eq(@article2.id)
    end

    it "updates a survey question" do
      @survey = AppData::Survey.create! surveyable_id: @article.id, surveyable_type: "AppData::Article"
      @question1 = AppData::Question.create! survey_id: @survey.id, question_text: "Test Question", question_type: "multiple_choice"
      @answer1 = AppData::Answer.create! question_id: @question1.id, answer_text: "Test Answer 1"
      @answer2 = AppData::Answer.create! question_id: @question1.id, answer_text: "Test Answer 2"

      request_payload = {
        organisation_id: @organisation.id,
        id: @survey.id,
        data: {
          attributes: {
            article_id: @article.id
          }, 
          relationships: {
            questions: {
              data: [
                { 
                  id: @question1.id,
                  question_text: "Question Text 1 UPDATED"
                },
              ]
            }
          },
          type: "surveys"
        }, 
      }

      put :update, params: request_payload

      expect(AppData::Survey.find(@survey.id).questions.find(@question1.id).question_text).to eq("Question Text 1 UPDATED")
    end

    it "updates a survey question's answer" do
      @survey = AppData::Survey.create! surveyable_id: @article.id, surveyable_type: "AppData::Article"
      @question1 = AppData::Question.create! survey_id: @survey.id, question_text: "Test Question", question_type: "multiple_choice"
      @answer1 = AppData::Answer.create! question_id: @question1.id, answer_text: "Test Answer 1"
      @answer2 = AppData::Answer.create! question_id: @question1.id, answer_text: "Test Answer 2"

      request_payload = {
        id: @survey.id,
        data: {
          attributes: {
            article_id: @article.id
          }, 
          relationships: {
            questions: {
              data: [
                { 
                  id: @question1.id,
                  question_text: "Question Text 1 UPDATED", 
                  question_type: "single_choice",
                  answers_attributes: [
                    { 
                      id: @answer1.id,
                      answer_text: "Answer Text 1 UPDATED"
                    }
                  ],
                },
              ]
            }
          },
          type: "surveys"
        }, 
      }

      put :update, params: request_payload

      expect(AppData::Survey.find(@survey.id).questions.find(@question1.id).answers.find(@answer1.id).answer_text).to eq("Answer Text 1 UPDATED")
    end
  end

  describe "POST delete" do
    it "delete a survey it's associated questions and answers, if there are no address_answers" do
      @survey = AppData::Survey.create! surveyable_id: @article.id, surveyable_type: "AppData::Article"
      @question1 = AppData::Question.create! survey_id: @survey.id, question_text: "Test Question", question_type: "multiple_choice"
      @answer1 = AppData::Answer.create! question_id: @question1.id, answer_text: "Test Answer 1"
      @answer2 = AppData::Answer.create! question_id: @question1.id, answer_text: "Test Answer 2"

      expect { delete :destroy, params: {organisation_id: @organisation.id, id: @survey.id} }.to \
        change { AppData::Survey.count }.by(-1).and \
        change { AppData::Question.count }.by(-1).and \
        change { AppData::Answer.count }.by(-2)
    end

    it "fails to delete a survey it's associated questions and answers becuase there are address_answers" do
      @survey = AppData::Survey.create! surveyable_id: @article.id, surveyable_type: "AppData::Article"
      @question1 = AppData::Question.create! survey_id: @survey.id, question_text: "Test Question", question_type: "multiple_choice"
      @answer1 = AppData::Answer.create! question_id: @question1.id, answer_text: "Test Answer 1"
      @answer2 = AppData::Answer.create! question_id: @question1.id, answer_text: "Test Answer 2"

      key = Eth::Key.new
      @address = Address.create! address: key.address  
      
      @address.address_answers.create! question: @question1, answer: @answer1
    
      survey_id = @survey.id
      question1_id = @question1.id
      answer1_id = @answer1.id

      expect { delete :destroy, params: {organisation_id: @organisation.id, id: @survey.id} }.to \
        change { AppData::Survey.count }.by(0).and \
        change { AppData::Question.count }.by(0).and \
        change { AppData::Answer.count }.by(0)
    end
  end

end