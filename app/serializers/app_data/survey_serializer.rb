class AppData::SurveySerializer < ActiveModel::Serializer
  attributes :id, :enable_at, :disable_at, :article_id

  belongs_to :article
  has_many :questions
  has_many :answers

  def article_id
    object.surveyable_id if object.surveyable_type === "AppData::Article"
  end

  type :survey
end