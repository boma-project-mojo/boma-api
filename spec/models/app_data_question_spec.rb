require 'rails_helper'

RSpec.describe AppData::Question, type: :model do
  before(:all) do
    @organisation = Organisation.create! name: "Mock Org"
    @article = AppData::Article.new article_type: :boma_news_article, title: "Mock Artilce", organisation_id: @organisation.id, content: "Mock Content" 
    @article.remote_image_url = "https://boma-production-images.s3.amazonaws.com/test.png"
    @article.save!

    @survey = AppData::Survey.new surveyable_id: @article.id, surveyable_type: "AppData::Article"
    @survey.save!
  end

  it "is valid with valid attributes" do
    @question = AppData::Question.new survey_id: @survey.id, question_text: "Test Question", question_type: "multiple_choice"
    expect(@question).to be_valid
  end

  it "is invalid without survey_id attributes" do
    @question = AppData::Question.new question_text: "Test Question", question_type: "multiple_choice"
    expect(@question).to be_invalid
  end

  it "is invalid without question_text attributes" do
    @question = AppData::Question.new survey_id: @survey.id, question_type: "multiple_choice"
    expect(@question).to be_invalid
  end

  it "is invalid without question_type attributes" do
    @question = AppData::Question.new question_text: "Test Question", survey_id: @survey.id
    expect(@question).to be_invalid
  end
end
