class AppData::Survey < AppData::Base
  attr_accessor :article_id

	before_destroy :check_survey_has_no_responses

  def check_survey_has_no_responses
  	return true if self.address_answers.count === 0
    errors.add(:base, "Sorry, you cannot delete a survey if it has any associated responses.")
    false
    throw(:abort)
  end

	belongs_to :surveyable, polymorphic: true

	has_many :questions, dependent: :destroy
	has_many :answers, through: :questions
	has_many :address_answers, through: :questions

	validates :surveyable_id, presence: true
	validates :surveyable_type, presence: true

	accepts_nested_attributes_for :questions

  after_commit :couch_update_or_create, on: [:create, :update, :destroy]

  # return the related Article.
	def article
    surveyable if surveyable_type == AppData::Article.name
  end

  # check that the Survey is enabled 
  def enabled?
    now = DateTime.now

    if self.enable_at.nil? # enable_at isn't set
      if self.disable_at.nil? # Handles the case where the survey is open forever
        return true
      elsif now < self.disable_at # disable_at is set and now is before the disable_at
        return true
      elsif now > self.disable_at # disable_at is set and now is after than disable_at
        return false
      end
    else # enabled_at is set
      if self.disable_at.nil? # Handles the case where the survey opens at enable_at and never closes
        if now > self.enable_at # now is after enable_at so open the survey
          return true
        end    
      else # disable_at is set 
        if now > self.enable_at and now < self.disable_at # now is before enable at so the surve is open
          return true
        end
      end 
    end
    # for any uncaught cases default to closed.
    return false
  end

  # Collate the results of the survey for displaying in the admin section
  def results
  	results = {}
  	results[:questions] = []
  	self.questions.each do |question|
 			answers = []
 			questions_for_json = question.as_json
 			questions_for_json[:answers] = answers

 			question.answers.each do |answer|
 				answer_total = answer.address_answers.count
 				answer = answer.as_json
 				answer[:total] = answer_total
 				questions_for_json[:answers] << answer
 			end
  		results[:questions] << questions_for_json
  	end
  	return results
  end

  def to_couch_data
    data = {
      id: self.id,
      enable_at: self.enable_at,
      disable_at: self.disable_at,
      questions: self.questions.map {|question| question.to_couch_data }
    }

    return data
  end

  # Run couch_update_or_create on the associated article to ensure that changes to the survey model are 
  # propagated to the article couchdb record
  def couch_update_or_create is_callback = false
    unless is_callback
      article.couch_update_or_create(true)
    end
  end
end
