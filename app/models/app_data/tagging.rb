class AppData::Tagging < AppData::Base
  belongs_to :tag, class_name: 'AppData::Tag', optional: true
  belongs_to :production, class_name: 'AppData::Production', foreign_key: 'taggable_id', optional: true
  belongs_to :event, class_name: 'AppData::Event', foreign_key: 'taggable_id', optional: true
  belongs_to :venue, class_name: 'AppData::Venue', foreign_key: 'taggable_id', optional: true
end