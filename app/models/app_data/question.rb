class AppData::Question < AppData::Base
  belongs_to :survey
  has_many :answers, dependent: :destroy
  accepts_nested_attributes_for :answers

  has_many :address_answers, through: :answers

  validates :question_text, presence: true
  validates :question_type, presence: true

  allowed_question_types = ["multiple_choice", "single_choice"]
  validates :question_type, :presence => {message: "can't be blank"}, :inclusion=> { in: allowed_question_types, message: "Question type must be one of #{allowed_question_types.join(',')}"}

  def to_couch_data
    data = {
      id: self.id,
      question_text: self.question_text,
      question_type: self.question_type,
      answers: self.answers.map{|a| a.to_couch_data}
    }

    return data
  end
end
