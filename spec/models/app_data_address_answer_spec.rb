require 'rails_helper'

RSpec.describe AppData::AddressAnswer, type: :model do
  before(:all) do
    @organisation = Organisation.create! name: "Mock Org"
    @article = AppData::Article.new article_type: :boma_news_article, title: "Mock Artilce", organisation_id: @organisation.id, content: "Mock Content" 
    @article.remote_image_url = "https://boma-production-images.s3.amazonaws.com/test.png"
    @article.save!

    @survey = AppData::Survey.new surveyable_id: @article.id, surveyable_type: "AppData::Article"
    @survey.save!

    @question1 = AppData::Question.new survey_id: @survey.id, question_text: "Test Question", question_type: "multiple_choice"
    @question1.save!

    @answer1 = AppData::Answer.new question_id: @question1.id, answer_text: "Test Answer 1"
    @answer1.save!

    @answer2 = AppData::Answer.new question_id: @question1.id, answer_text: "Test Answer 2"
    @answer2.save!

    @question2 = AppData::Question.new survey_id: @survey.id, question_text: "Test Question", question_type: "single_choice"
    @question2.save!

    @q2answer1 = AppData::Answer.new question_id: @question2.id, answer_text: "Test Answer 1"
    @q2answer1.save!

    @q2answer2 = AppData::Answer.new question_id: @question2.id, answer_text: "Test Answer 2"
    @q2answer2.save!

    key = Eth::Key.new
    @address = Address.create! address: key.address  
  end

  it "is valid with valid attributes" do
    @address_answer = AppData::AddressAnswer.new question_id: @question1.id, answer_id: @answer1.id, address_id: @address.id
    expect(@address_answer).to be_valid
  end

  it "is valid when the question is multiple_choice and address_answer doesn't already exist for this address and answer" do
    @address_answer1 = AppData::AddressAnswer.create! question_id: @question1.id, answer_id: @answer1.id, address_id: @address.id
    @address_answer2 = AppData::AddressAnswer.new question_id: @question1.id, answer_id: @answer2.id, address_id: @address.id
    expect(@address_answer2).to be_valid
  end

  it "is invalid when the question is single_choice and address_answer already exists for this address and question" do
    @address_answer1 = AppData::AddressAnswer.create! question_id: @question2.id, answer_id: @answer1.id, address_id: @address.id
    @address_answer2 = AppData::AddressAnswer.new question_id: @question2.id, answer_id: @answer2.id, address_id: @address.id
    expect(@address_answer2).to be_invalid
  end

  it "is invalid without question_id attributes" do
    @address_answer = AppData::AddressAnswer.new answer_id: @answer1.id, address_id: @address.id
    expect(@address_answer).to be_invalid
  end

  it "is invalid without answer_id attributes" do
    @address_answer = AppData::AddressAnswer.new question_id: @question1.id, address_id: @address.id
    expect(@address_answer).to be_invalid
  end

  it "is invalid without address_id attributes" do
    @address_answer = AppData::AddressAnswer.new question_id: @question1.id, answer_id: @answer1.id
    expect(@address_answer).to be_invalid
  end

  it "is invalid when the address has already submitted an AppData::AddressAnswer for this question_id and the question is single_choice" do
    @address_answer1 = AppData::AddressAnswer.create! question_id: @question2.id, answer_id: @q2answer1.id, address_id: @address.id
    @address_answer2 = AppData::AddressAnswer.new question_id: @question2.id, answer_id: @q2answer1.id, address_id: @address.id
    expect(@address_answer2).to be_invalid
  end

  it "is invalid when the address has already submitted an AppData::AddressAnswer for this question_id and answer_id and the question is multiple_choice" do
    @address_answer1 = AppData::AddressAnswer.create! question_id: @question1.id, answer_id: @answer1.id, address_id: @address.id
    @address_answer2 = AppData::AddressAnswer.new question_id: @question1.id, answer_id: @answer1.id, address_id: @address.id
    expect(@address_answer2).to be_invalid
  end
end