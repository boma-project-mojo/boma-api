class AppData::AnswerSerializer < ActiveModel::Serializer
  attributes :id, :answer_text, :total_responses

  def total_responses
    object.total_responses
  end

  type :answer
end