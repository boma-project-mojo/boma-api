class AppData::Tag < AppData::Base

	include AASM

	aasm do
	  state :draft
	  state :hidden
	  state :published, :initial => true

	  event :publish do
	    transitions :from => [:draft, :hidden], :to => :published
	  end

	  event :hide do
	    transitions :from => [:published], :to => :hidden
	  end	  
	end

	# has_paper_trail
	acts_as_paranoid

  after_commit :couch_update_or_create, on: [:create, :update, :destroy]

  belongs_to :festival, optional: true
  belongs_to :organisation, optional: true

  has_many :taggings
  has_many :productions, through: :taggings
  has_many :venues, through: :taggings

	validates :name, :presence => {message: "can't be blank"}, :uniqueness => {:scope => [:festival_id, :tag_type]}

	allowed_tag_types = ["event", "production", "retailer", "news_tag", "link_tag", "talks_tag", "community_article", "performance_venue", "article"]
	validates :tag_type, :presence => {message: "can't be blank"}, :inclusion=> { in: allowed_tag_types, message: "Tag type must be one of #{allowed_tag_types.join(',')}"}

	# Must have festival or organisation relationships
  validates :festival_id, :presence => {message: "can't be blank if organisation_id isn't present"}, unless: :organisation_id
  validates :organisation_id, :presence => {message: "can't be blank if festival_id isn't present"}, unless: :festival_id

	def to_couch_data

		festival_id = festival.id rescue nil
		organisation_id = organisation.id rescue nil

		data = {
			name: name,
			tag_type: tag_type,
			aasm_state: aasm_state,
			description: description,
			festival_id: festival_id,
			organisation_id: organisation_id
		}

	end

	def couch_update_or_create is_callback = false
		prefix = self.class.name.downcase.split(':').last
    doc = couch_get
    unless doc.nil?
      doc['data'] = to_couch_data
      couch_save_doc(doc)
    else
      if published? and valid_for_app?
        doc = couch_save_doc('_id' => "#{prefix}_2_#{id}", 'data' => to_couch_data)
      end
    end
    
    unless is_callback
			# Only update productions if entire tag is delete.
      if self.deleted?
				productions.select{|pr| pr.valid_for_app? }.each do |p|
					p.couch_update_or_create true
				end
			end
		end
	end

end
