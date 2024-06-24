class AppData::AddressAnswer < AppData::Base
  belongs_to :address
  belongs_to :question
  belongs_to :answer

  has_one :survey, through: :question

  # For multiple_choice questions only allow one record of each of the questions answer per address 
  validates :answer, :uniqueness => {:scope => [:address_id, :question_id], message: "Sorry, you can only answer this question once."}, if: proc { |aa| aa.question.question_type === 'multiple_choice' rescue false }
  # For single_choice only allow one answer per question per address
  validates :question, :uniqueness => {:scope => [:address_id], message: "Sorry, you can only answer this question once."}, if: proc { |aa| aa.question.question_type === 'single_choice' rescue false }

  validate :survey_is_open

  # validate that the current time is after the time the survey
  # is set to be enabled at and before it is set to be disabled at
  def survey_is_open
    unless self.survey.nil? or self.survey.enabled?
      errors.add(:base, "Survey closed.")
    end
  end
end
