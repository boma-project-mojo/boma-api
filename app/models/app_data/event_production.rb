class AppData::EventProduction < AppData::Base
  belongs_to :event, class_name: 'AppData::Event', dependent: :destroy, optional: true
  belongs_to :production, class_name: 'AppData::Production', optional: true

  after_destroy :touch_production

  # update the couchdb record for the related production
  def touch_production
    self.production.couch_update_or_create
  end
end