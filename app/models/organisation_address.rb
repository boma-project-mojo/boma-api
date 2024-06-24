class OrganisationAddress < ApplicationRecord
  belongs_to :address
  belongs_to :organisation
  has_many :tokens, through: :address

  validates :organisation, :uniqueness => {:scope => [:address_id], message: "A relationships exists between this address and this organisation"}

  acts_as_paranoid
end
