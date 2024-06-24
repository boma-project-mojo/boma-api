class AppData::Answer < AppData::Base
  belongs_to :question
  has_many :address_answers

  validates :answer_text, presence: true

  # Return a count of the number of responses this Answer has attracted.  
  def total_responses
    self.address_answers.count
  end

  def to_couch_data
    data = {
      id: self.id,
      answer_text: self.answer_text
    }

    return data
  end
end
