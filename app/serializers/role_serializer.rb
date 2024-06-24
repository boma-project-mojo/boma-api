class RoleSerializer < ActiveModel::Serializer
  attributes :id, :name, :resource_id, :resource_type, :venue_id
  type :role
  # has_many :users

  def venue_id
    if object.resource_type == "AppData::Venue"
      object.resource_id
    else
      nil
    end
  end

  def users
    object.users
  end
end
