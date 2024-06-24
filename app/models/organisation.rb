class Organisation < ApplicationRecord
  resourcify

  has_many :festivals
  has_many :token_types

  has_many :organisation_addresses
  has_many :addresses, through: :organisation_addresses

  has_many :articles, class_name: 'AppData::Article'
  has_many :tags, class_name: 'AppData::Tag'

  validates :name, presence: true
  
  # generate the app_url_schema which is used when creating deep links 
  # for the app 
  def app_url_schema
    self.bundle_id.gsub("\.", "")
  end

  def couchdb_name
  	self.name.parameterize.underscore+"_"+self.id.to_s
  end
end
