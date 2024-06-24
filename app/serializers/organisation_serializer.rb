class OrganisationSerializer < ActiveModel::Serializer
  attributes :id, :name, :community_articles_enabled, :app_versions
  type :organisation

  def image_name
    object.image.url
  end

  def app_versions
    OrganisationAddress.where(organisation_id: object.id).group(:app_version).count.map {|key, value| {'name': key, 'count': value } }
  end
end
