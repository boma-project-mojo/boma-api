class AppData::QuestionSerializer < ActiveModel::Serializer
  attributes :id, :question_text, :question_type

  has_many :answers

  type :question
end