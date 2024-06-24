require 'rails_helper'

RSpec.describe AppData::Answer, type: :model do
  before(:all) do
    @organisation = Organisation.create! name: "Mock Org"
    @article = AppData::Article.new article_type: :boma_news_article, title: "Mock Artilce", organisation_id: @organisation.id, content: "Mock Content" 
    @article.remote_image_url = "https://boma-production-images.s3.amazonaws.com/test.png"
    @article.save!

    @survey = AppData::Survey.new surveyable_id: @article.id, surveyable_type: "AppData::Article"
    @survey.save!

    @question = AppData::Question.new survey_id: @survey.id, question_text: "Test Question", question_type: "multiple_choice"
    @question.save!
  end

  it "is valid with valid attributes" do
    @answer = AppData::Answer.new question_id: @question.id, answer_text: "Test Answer"
    expect(@answer).to be_valid
  end

  it "is invalid without question_id attributes" do
    @answer = AppData::Answer.new answer_text: "Test Answer"
    expect(@answer).to be_invalid
  end

  it "is invalid without answer_text attributes" do
    @answer = AppData::Answer.new question_id: @question.id
    expect(@answer).to be_invalid
  end
end
