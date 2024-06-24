class AddressSerializer < ActiveModel::Serializer
  attributes :id, :address, :created_at, :updated_at, :organisation_addresses, :activities, :push_notifications

  def organisation_addresses
    object.organisation_addresses
  end

  def activities
    object.activities.order('updated_at DESC').limit(12)
  end

  def push_notifications
    object.push_notifications.order('updated_at DESC').limit(12)
  end

  type :address
end