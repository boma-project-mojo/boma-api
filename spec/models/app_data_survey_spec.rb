require 'rails_helper'

RSpec.describe AppData::Survey, type: :model do
  before(:all) do
    @organisation = Organisation.create! name: "Mock Org"
    @article = AppData::Article.new article_type: :boma_news_article, title: "Mock Artilce", organisation_id: @organisation.id, content: "Mock Content" 
    @article.remote_image_url = "https://boma-production-images.s3.amazonaws.com/test.png"
    @article.save!
  end

  it "is valid with valid attributes" do
    @survey = AppData::Survey.new surveyable_id: @article.id, surveyable_type: "AppData::Article"
    expect(@survey).to be_valid
  end

  it "belongs to an article" do
    @survey = AppData::Survey.new surveyable_id: @article.id, surveyable_type: "AppData::Article"
    expect(@survey.article.title).to eq @article.title
  end

  it "is invalid without surveyable_id attribute" do
    @survey = AppData::Survey.new surveyable_type: "AppData::Article"
    expect(@survey).to be_invalid
  end

  it "is invalid without surveyable_type attribute" do
    @survey = AppData::Survey.new surveyable_id: @article.id
    expect(@survey).to be_invalid
  end

  it "survey.results returns json formatted totals for all submissions" do
    @organisation = Organisation.create! name: "Mock Org"
    @article = AppData::Article.new article_type: :boma_news_article, title: "Mock Artilce", organisation_id: @organisation.id, content: "Mock Content" 
    @article.remote_image_url = "https://boma-production-images.s3.amazonaws.com/test.png"
    @article.save!

    @survey = AppData::Survey.new surveyable_id: @article.id, surveyable_type: "AppData::Article"
    @survey.save!

    @question = AppData::Question.new survey_id: @survey.id, question_text: "Test Question", question_type: "multiple_choice"
    @question.save!

    @answer1 = AppData::Answer.new question_id: @question.id, answer_text: "Test Answer 1"
    @answer1.save!

    @answer2 = AppData::Answer.new question_id: @question.id, answer_text: "Test Answer 2"
    @answer2.save!

    @answer3 = AppData::Answer.new question_id: @question.id, answer_text: "Test Answer 3"
    @answer3.save!

    key = Eth::Key.new
    @address1 = Address.create! address: key.address  
    key = Eth::Key.new
    @address2 = Address.create! address: key.address  
    key = Eth::Key.new
    @address3 = Address.create! address: key.address  

    @address_answer1 = AppData::AddressAnswer.create! question_id: @question.id, answer_id: @answer1.id, address_id: @address1.id
    @address_answer2 = AppData::AddressAnswer.create! question_id: @question.id, answer_id: @answer2.id, address_id: @address2.id
    @address_answer3 = AppData::AddressAnswer.create! question_id: @question.id, answer_id: @answer3.id, address_id: @address3.id
    @address_answer1 = AppData::AddressAnswer.create! question_id: @question.id, answer_id: @answer1.id, address_id: @address3.id
  
    results = @survey.results

    expect(results[:questions][0][:answers].find{|a| a['id'] === @answer1.id}[:total]).to eq(2)
    expect(results[:questions][0][:answers].find{|a| a['id'] === @answer2.id}[:total]).to eq(1)
    expect(results[:questions][0][:answers].find{|a| a['id'] === @answer3.id}[:total]).to eq(1)
  end

  it "survey to_couch_data includes the survey all it's associated questions and answers" do
    @article = AppData::Article.new article_type: :boma_news_article, title: "Mock Artilce", organisation_id: @organisation.id, content: "Mock Content" 
    @article.remote_image_url = "https://boma-production-images.s3.amazonaws.com/test.png"
    @article.save!

    @survey = AppData::Survey.new surveyable_id: @article.id, surveyable_type: "AppData::Article"
    @survey.save!

    @question = AppData::Question.new survey_id: @survey.id, question_text: "Test Question", question_type: "multiple_choice"
    @question.save!

    @answer1 = AppData::Answer.new question_id: @question.id, answer_text: "Test Answer 1"
    @answer1.save!

    @answer2 = AppData::Answer.new question_id: @question.id, answer_text: "Test Answer 2"
    @answer2.save!

    @answer3 = AppData::Answer.new question_id: @question.id, answer_text: "Test Answer 3"
    @answer3.save!

    @question2 = AppData::Question.new survey_id: @survey.id, question_text: "Test Question 2", question_type: "multiple_choice"
    @question2.save!

    @q2answer1 = AppData::Answer.new question_id: @question2.id, answer_text: "Q2 Test Answer 1"
    @q2answer1.save!

    @q2answer2 = AppData::Answer.new question_id: @question2.id, answer_text: "Q2 Test Answer 2"
    @q2answer2.save!

    @q2answer3 = AppData::Answer.new question_id: @question2.id, answer_text: "Q2 Test Answer 3"
    @q2answer3.save!

    couch_data = @survey.to_couch_data

    expect(couch_data[:questions][0][:question_text]).to eq('Test Question')
    expect(couch_data[:questions][0][:answers].count).to eq(3)
    expect(couch_data[:questions][0][:answers][0][:answer_text]).to eq('Test Answer 1')
    expect(couch_data[:questions][1][:question_text]).to eq('Test Question 2')
    expect(couch_data[:questions][1][:answers][1][:answer_text]).to eq('Q2 Test Answer 2')
  end
end