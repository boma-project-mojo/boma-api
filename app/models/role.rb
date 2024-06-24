class Role < ApplicationRecord
  has_and_belongs_to_many :users, :join_table => :users_roles
  has_many :users_roles, class_name: "UsersRoles"
  belongs_to :venue, foreign_key: :resource_id, class_name: "AppData::Venue", optional: true
  belongs_to :resource,
             :polymorphic => true,
             :optional => true

  validates :resource_type,
            :inclusion => { :in => Rolify.resource_types },
            :allow_nil => true

  scopify

  # Overwriting the as_json function for venue based roles so that venue attributes can 
  # be flattened onto the model removing need for a query to be sent per role from admin
  # section to get venue details.  
  def as_json(options = {})
    if(venue)
      {
        id: id,
        resource_id: resource_id,
        resource_type: resource_type,
        venue_name: venue.name,
        festival_name: venue.festival.name
      }
    else
      super
    end

  end
end
