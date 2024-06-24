include ActionView::Helpers::NumberHelper

class Festival < ApplicationRecord
  include Couchdb

  attr_accessor :resize_to_fit

  belongs_to :organisation

  has_many :productions, class_name: 'AppData::Production'
  has_many :events, class_name: 'AppData::Event'
  has_many :venues, class_name: 'AppData::Venue'
  has_many :tags, class_name: 'AppData::Tag'
  has_many :pages, class_name: 'AppData::Page'
  has_many :people, class_name: 'AppData::Person'
  has_many :articles, class_name: 'AppData::Article'

  has_many :push_notifications

  has_many :token_types

  has_many :messages

  validates :name, :presence => {message: "can't be blank"}
  validates :start_date, :presence => {message: "can't be blank"}
  validates :end_date, :presence => {message: "can't be blank"}
  # validates :fcm_topic_id, :presence => {message: "can't be blank"}
  # validates :fcm_topic_id, format: { without: /\s/,  message: "can't have spaces" }
  # validates :fcm_topic_id, uniqueness: true
  validates :timezone, :presence => {message: "can't be blank"}
  validates :organisation, :presence => {message: "can't be blank"}
  validates :schedule_modal_type, :presence => {message: "can't be blank"}
  validates :bundle_id, :presence => {message: "can't be blank"}, format: { with: /\Acom\.[A-Za-z0-9]*\.[A-Za-z]*\z/, message: "must be in the format com.something.something" }

  resourcify
  
  validate :has_image

  validate :end_date_after_start_date

  after_commit :couch_update_or_create, on: [:create, :update, :destroy]

  include AASM

  aasm do 
    state :draft, :initial => true
    state :preview
    state :published

    event :preview do
      transitions :from => [:draft], :to => :preview
    end

    event :publish do
      transitions :from => [:draft, :preview], :to => :published
    end

    event :unpublish do
      transitions :from => [:published, :preview], :to => :draft
    end
  end

  # Fallback for models that don't have this state
  def cancelled?
    false
  end

  def deleted?
    false
  end
  
  # Check that the start_date is after the end_date
  def end_date_after_start_date
    if self.end_date and self.start_date
      unless(self.end_date > self.start_date)
        errors.add(:end_date, "must be after start date")
      end
    end
  end

  # Check the record has an image
  def has_image
    unless image.is_a? String    
      if image.url.nil? and image.file.nil?
        errors.add(:image, "must be added")
      end
    end
  end

  mount_uploader :image, ImageUploader

  after_create :create_couchdb_design_docs

  # COUCHDB DESIGN DOCS

  # The following method creates the couchdb design docs used by the app for populating the pouchdb 
  # database and by the pouch-dump library (https://gitlab.com/boma-hq/pouch-dump) to create data
  # dumps that are shipped with production apps.  
  #
  # The design docs are created using the couchdb Fauxton UI which can be found at the `/_utils`
  # from any of the couchdb instances.  To access it locally use `http://localhost:5984/_utils/`.  
  #
  # To create/edit design docs: 
  #
  # 1.  navigate to a database
  # 2.  click 'Design Documents' in the left sidebar menu
  # 3.  click the `+` icon to create a new design doc or click the spanner icon to edit or clone an  
  #     existing one
  # 4.  use the UI to write the functions in erlang or javascript.  Erlang is significantly quicker 
  #     and was chosen for this reason before caching was added to the couchdb instances.  
  # 5.  test the functions by saving the design doc and checking the list of documents returned is
  #     as expected
  # 6.  once finalised, copy and paste the function here and check in the changes.  
  def create_couchdb_design_docs
    couchdb = CouchDB.database!(self.couchdb_name) 

    # Auth doc
    doc = {
      "_id" => "_design/only_admins",
      "data" => {
        validate_doc_update: "function (newDoc, oldDoc, userCtx) {
          var role = \"blogger\";
          if (userCtx.roles.indexOf(\"_admin\") === -1 && userCtx.roles.indexOf(role) === -1) {
            throw({forbidden : \"Only users with role \" + role + \" or an admin can modify this database.\"});
          }
        }"
      }
    }

    # organisation level views
    couch_update_or_create_design_doc(doc)

    doc = {
      "_id" => "_design/by_model_name_erlang",
      "language" => "erlang",
      "views" => {
        "all_articles": {
          "map": "fun({Doc}) ->\n\tID = proplists:get_value(<<\"_id\">>, Doc, null),\n\tIDParts = re:split(ID, \"_\"),\n  DocType = lists:nth(1, IDParts),\n\n  case DocType of\n    <<\"article\">> ->\n    \tcase proplists:get_value(<<\"data\">>, Doc, null) of\n    \t\t{Data} ->\n    \t\t\tState = proplists:get_value(<<\"aasm_state\">>, Data),\n          case State of\n          \t<<\"published\">> ->\n          \t\tEmit(ID, 1);\n        \t\t_ ->\n    \t\t\t\t\tok\n    \t\t\tend;\n    \t\t_ ->\n    \t\t\tok\n    \tend;\n  \t_ ->\n    \tok\n  end\nend."
        },
        "all_boma_articles": {
          "map": "fun({Doc}) ->\n\tID = proplists:get_value(<<\"_id\">>, Doc, null),\n\tIDParts = re:split(ID, \"_\"),\n  DocType = lists:nth(1, IDParts),\n\n  case DocType of\n    <<\"article\">> ->\n    \tcase proplists:get_value(<<\"data\">>, Doc, null) of\n    \t\t{Data} ->\n    \t\t\tArticleType = proplists:get_value(<<\"article_type\">>, Data),\n          State = proplists:get_value(<<\"aasm_state\">>, Data),\n          case State of\n            <<\"unpublished\">> ->\n              Emit(ID, 1);\n            <<\"published\">> ->\n              case ArticleType of\n                <<\"boma_article\">> ->\n                  Emit(ID, 1);\n                <<\"boma_audio_article\">> ->\n                  Emit(ID, 1);\n                <<\"boma_video_article\">> ->\n                  Emit(ID, 1);\n                <<\"boma_news_article\">> ->\n                  Emit(ID, 1);\n                _ ->\n        \t\t\t\t\tok\n        \t\t\tend;\n        \t\t_ ->\n        \t\t  ok\n        \t\tend;\n    \t\t_ ->\n    \t\t\tok\n    \tend;\n    <<\"tag\">> ->\n      case proplists:get_value(<<\"data\">>, Doc, null) of\n    \t\t{Data} ->\n    \t\t\tTagType = proplists:get_value(<<\"tag_type\">>, Data),\n          State = proplists:get_value(<<\"aasm_state\">>, Data),\n          case State of\n            <<\"unpublished\">> ->\n              Emit(ID, 1);\n            <<\"published\">> ->\n              case TagType of\n              \t<<\"article\">> ->\n              \t\tEmit(ID, 1);\n              \t<<\"news_tag\">> ->\n              \t  Emit(ID, 1);\n              \t<<\"talks_tag\">> ->\n              \t  Emit(ID, 1);\n            \t\t_ ->\n        \t\t\t\t\tok\n        \t\t\tend;\n        \t\t_ ->\n        \t\t  ok\n        \t\tend;\n    \t\t_ ->\n    \t\t\tok\n    \tend;\n  \t_ ->\n    \tok\n  end\nend."
        },
        "all_boma_news_articles": {
          "map": "fun({Doc}) ->\n\tID = proplists:get_value(<<\"_id\">>, Doc, null),\n\tIDParts = re:split(ID, \"_\"),\n  DocType = lists:nth(1, IDParts),\n\n  case DocType of\n    <<\"article\">> ->\n    \tcase proplists:get_value(<<\"data\">>, Doc, null) of\n    \t\t{Data} ->\n    \t\t\tArticleType = proplists:get_value(<<\"article_type\">>, Data),\n          State = proplists:get_value(<<\"aasm_state\">>, Data),\n          case State of\n            <<\"unpublished\">> ->\n              Emit(ID, 1);\n            <<\"published\">> ->\n              case ArticleType of\n              \t<<\"boma_news_article\">> ->\n              \t\tEmit(ID, 1);\n            \t\t_ ->\n        \t\t\t\t\tok\n        \t\t\tend;\n        \t\t_ ->\n        \t\t  ok\n        \t\tend;\n    \t\t_ ->\n    \t\t\tok\n    \tend;\n  \t_ ->\n    \tok\n  end\nend."
        },
        "all_boma_audio_articles": {
          "map": "fun({Doc}) ->\n\tID = proplists:get_value(<<\"_id\">>, Doc, null),\n\tIDParts = re:split(ID, \"_\"),\n  DocType = lists:nth(1, IDParts),\n\n  case DocType of\n    <<\"article\">> ->\n    \tcase proplists:get_value(<<\"data\">>, Doc, null) of\n    \t\t{Data} ->\n    \t\t\tArticleType = proplists:get_value(<<\"article_type\">>, Data),\n          State = proplists:get_value(<<\"aasm_state\">>, Data),\n          case State of\n            <<\"unpublished\">> ->\n              Emit(ID, 1);\n            <<\"published\">> ->\n              case ArticleType of\n              \t<<\"boma_audio_article\">> ->\n              \t\tEmit(ID, 1);\n            \t\t_ ->\n        \t\t\t\t\tok\n        \t\t\tend;\n        \t\t_ ->\n        \t\t  ok\n        \t\tend;\n    \t\t_ ->\n    \t\t\tok\n    \tend;\n  \t_ ->\n    \tok\n  end\nend."
        },
        "all_boma_video_articles": {
          "map": "fun({Doc}) ->\n\tID = proplists:get_value(<<\"_id\">>, Doc, null),\n\tIDParts = re:split(ID, \"_\"),\n  DocType = lists:nth(1, IDParts),\n\n  case DocType of\n    <<\"article\">> ->\n    \tcase proplists:get_value(<<\"data\">>, Doc, null) of\n    \t\t{Data} ->\n    \t\t\tArticleType = proplists:get_value(<<\"article_type\">>, Data),\n          State = proplists:get_value(<<\"aasm_state\">>, Data),\n          case State of\n            <<\"unpublished\">> ->\n              Emit(ID, 1);\n            <<\"published\">> ->\n              case ArticleType of\n              \t<<\"boma_video_article\">> ->\n              \t\tEmit(ID, 1);\n            \t\t_ ->\n        \t\t\t\t\tok\n        \t\t\tend;\n        \t\t_ ->\n        \t\t  ok\n        \t\tend;\n    \t\t_ ->\n    \t\t\tok\n    \tend;\n  \t_ ->\n    \tok\n  end\nend."
        },
        "all_community_articles": {
          "map": "fun({Doc}) ->\n\tID = proplists:get_value(<<\"_id\">>, Doc, null),\n\tIDParts = re:split(ID, \"_\"),\n  DocType = lists:nth(1, IDParts),\n\n  case DocType of\n    <<\"article\">> ->\n    \tcase proplists:get_value(<<\"data\">>, Doc, null) of\n    \t\t{Data} ->\n    \t\t\tArticleType = proplists:get_value(<<\"article_type\">>, Data),\n          case ArticleType of\n          \t<<\"community_article\">> ->\n          \t\tEmit(ID, 1);\n        \t\t_ ->\n    \t\t\t\t\tok\n    \t\t\tend;\n    \t\t_ ->\n    \t\t\tok\n    \tend;\n    <<\"tag\">> ->\n  \t  case proplists:get_value(<<\"data\">>, Doc, null) of\n    \t\t{Data} ->\n    \t\t\tTagType = proplists:get_value(<<\"tag_type\">>, Data),\n    \t\t\tcase TagType of\n            <<\"community_article\">> ->\n              Emit(ID, 1);\n            _ ->\n              ok\n            end;\n    \t\t_ ->\n    \t\t\tok\n    \tend;\n  \t_ ->\n    \tok\n  end\nend."
        },
        "all_festivals": {
          "map": "fun({Doc}) ->\n\tID = proplists:get_value(<<\"_id\">>, Doc, null),\n\tIDParts = re:split(ID, \"_\"),\n  DocType = lists:nth(1, IDParts),\n\n  case DocType of\n    <<\"festival\">> ->\n  \t\tEmit(ID, 1);\n  \t_ ->\n    \tok\n  end\nend."
        },
        "all_tags": {
          "map": "fun({Doc}) ->\n\tID = proplists:get_value(<<\"_id\">>, Doc, null),\n\tIDParts = re:split(ID, \"_\"),\n  DocType = lists:nth(1, IDParts),\n\n  case DocType of\n    <<\"tag\">> ->\n  \t\tEmit(ID, 1);\n  \t_ ->\n    \tok\n  end\nend."
        },
        "community_events_by_start_date": {
          "map": "fun({Doc}) ->\n\tID = proplists:get_value(<<\"_id\">>, Doc, null),\n\tIDParts = re:split(ID, \"_\"),\n  DocType = lists:nth(1, IDParts),\n\n  case DocType of\n    <<\"event\">> ->\n    \tcase proplists:get_value(<<\"data\">>, Doc, null) of\n    \t\t{Data} ->\n    \t\t\tEventType = proplists:get_value(<<\"event_type\">>, Data),\n    \t\t\tPrivateEvent = proplists:get_value(<<\"private_event\">>, Data),\n          case PrivateEvent of\n            false ->\n              case EventType of\n          \t    <<\"community_event\">> ->\n          \t\t    Emit(ID, 1);\n        \t\t    _ ->\n    \t\t\t\t\t    ok\n    \t\t\t    end;\n    \t\t\t  _ ->\n              ok\n    \t\t\tend;\n    \t\t_ ->\n    \t\t\tok\n    \tend;\n  \t<<\"venue\">> ->\n  \t\tcase proplists:get_value(<<\"data\">>, Doc, null) of\n    \t\t{Data} ->\n\t    \t\tVenueType = proplists:get_value(<<\"venue_type\">>, Data),\n\t          case VenueType of\n\t          \t<<\"community_venue\">> ->\n\t          \t\tEmit(ID, 1);\n        \t\t_ ->\n    \t\t\t\t\tok\n    \t\t\tend;\n    \t\t_ ->\n    \t\t\tok\n\t    end;\n  \t_ ->\n    \tok\n  end\nend."
        },
        "preload_boma_articles": {
          "map": "fun({Doc}) ->\n\tID = proplists:get_value(<<\"_id\">>, Doc, null),\n\tIDParts = re:split(ID, \"_\"),\n  DocType = lists:nth(1, IDParts),\n\n  case DocType of\n    <<\"article\">> ->\n    \tcase proplists:get_value(<<\"data\">>, Doc, null) of\n    \t\t{Data} ->\n    \t\t\tArticleType = proplists:get_value(<<\"article_type\">>, Data),\n          case ArticleType of\n          \t<<\"boma_article\">> ->\n          \t\tPreload = proplists:get_value(<<\"preload\">>, Data),\n              case Preload of\n                1 ->\n                  Emit(ID, 1);\n                _ ->\n                  ok\n                end;\n        \t\t_ ->\n    \t\t\t\t\tok\n    \t\t\tend;\n    \t\t_ ->\n    \t\t\tok\n    \tend;\n  \t_ ->\n    \tok\n  end\nend."
        },
        "preload_boma_news_articles": {
          "map": "fun({Doc}) ->\n\tID = proplists:get_value(<<\"_id\">>, Doc, null),\n\tIDParts = re:split(ID, \"_\"),\n  DocType = lists:nth(1, IDParts),\n\n  case DocType of\n    <<\"article\">> ->\n    \tcase proplists:get_value(<<\"data\">>, Doc, null) of\n    \t\t{Data} ->\n    \t\t\tArticleType = proplists:get_value(<<\"article_type\">>, Data),\n          case ArticleType of\n          \t<<\"boma_news_article\">> ->\n          \t\tPreload = proplists:get_value(<<\"preload\">>, Data),\n              case Preload of\n                1 ->\n                  Emit(ID, 1);\n                _ ->\n                  ok\n                end;\n        \t\t_ ->\n    \t\t\t\t\tok\n    \t\t\tend;\n    \t\t_ ->\n    \t\t\tok\n    \tend;\n  \t_ ->\n    \tok\n  end\nend."
        },
        "preload_boma_audio_articles": {
          "map": "fun({Doc}) ->\n\tID = proplists:get_value(<<\"_id\">>, Doc, null),\n\tIDParts = re:split(ID, \"_\"),\n  DocType = lists:nth(1, IDParts),\n\n  case DocType of\n    <<\"article\">> ->\n    \tcase proplists:get_value(<<\"data\">>, Doc, null) of\n    \t\t{Data} ->\n    \t\t\tArticleType = proplists:get_value(<<\"article_type\">>, Data),\n          case ArticleType of\n          \t<<\"boma_audio_article\">> ->\n          \t\tPreload = proplists:get_value(<<\"preload\">>, Data),\n              case Preload of\n                1 ->\n                  Emit(ID, 1);\n                _ ->\n                  ok\n                end;\n        \t\t_ ->\n    \t\t\t\t\tok\n    \t\t\tend;\n    \t\t_ ->\n    \t\t\tok\n    \tend;\n  \t_ ->\n    \tok\n  end\nend."
        },
        "preload_boma_video_articles": {
          "map": "fun({Doc}) ->\n\tID = proplists:get_value(<<\"_id\">>, Doc, null),\n\tIDParts = re:split(ID, \"_\"),\n  DocType = lists:nth(1, IDParts),\n\n  case DocType of\n    <<\"article\">> ->\n    \tcase proplists:get_value(<<\"data\">>, Doc, null) of\n    \t\t{Data} ->\n    \t\t\tArticleType = proplists:get_value(<<\"article_type\">>, Data),\n          case ArticleType of\n          \t<<\"boma_video_article\">> ->\n          \t\tPreload = proplists:get_value(<<\"preload\">>, Data),\n              case Preload of\n                1 ->\n                  Emit(ID, 1);\n                _ ->\n                  ok\n                end;\n        \t\t_ ->\n    \t\t\t\t\tok\n    \t\t\tend;\n    \t\t_ ->\n    \t\t\tok\n    \tend;\n  \t_ ->\n    \tok\n  end\nend."
        },
        "preload_community_articles": {
          "map": "fun({Doc}) ->\n\tID = proplists:get_value(<<\"_id\">>, Doc, null),\n\tIDParts = re:split(ID, \"_\"),\n  DocType = lists:nth(1, IDParts),\n\n  case DocType of\n    <<\"article\">> ->\n    \tcase proplists:get_value(<<\"data\">>, Doc, null) of\n    \t\t{Data} ->\n    \t\t\tArticleType = proplists:get_value(<<\"article_type\">>, Data),\n          case ArticleType of\n          \t<<\"community_article\">> ->\n          \t\tPreload = proplists:get_value(<<\"preload\">>, Data),\n              case Preload of\n                1 ->\n                  Emit(ID, 1);\n                _ ->\n                  ok\n                end;\n        \t\t_ ->\n    \t\t\t\t\tok\n    \t\t\tend;\n    \t\t_ ->\n    \t\t\tok\n    \tend;\n  \t<<\"tag\">> ->\n  \t  case proplists:get_value(<<\"data\">>, Doc, null) of\n    \t\t{Data} ->\n    \t\t\tTagType = proplists:get_value(<<\"tag_type\">>, Data),\n    \t\t\tcase TagType of\n            <<\"community_article\">> ->\n              Emit(ID, 1);\n            _ ->\n              ok\n            end;\n    \t\t_ ->\n    \t\t\tok\n    \tend;\n  \t_ ->\n    \tok\n  end\nend."
        },
        "private_community_events_by_start_time": {
          "map": "fun({Doc}) ->\n\tID = proplists:get_value(<<\"_id\">>, Doc, null),\n\tIDParts = re:split(ID, \"_\"),\n  DocType = lists:nth(1, IDParts),\n\n  case DocType of\n    <<\"event\">> ->\n    \tcase proplists:get_value(<<\"data\">>, Doc, null) of\n    \t\t{Data} ->\n    \t\t\tEventType = proplists:get_value(<<\"event_type\">>, Data),\n    \t\t\tPrivateEvent = proplists:get_value(<<\"private_event\">>, Data),\n          case PrivateEvent of\n            true ->\n              case EventType of\n          \t    <<\"community_event\">> ->\n          \t\t    Emit(ID, 1);\n        \t\t    _ ->\n    \t\t\t\t\t    ok\n    \t\t\t    end;\n    \t\t\t  _ ->\n              ok\n    \t\t\tend;\n    \t\t_ ->\n    \t\t\tok\n    \tend;\n  \t_ ->\n    \tok\n  end\nend."
        },
        "all_pages": {
          "map": "fun({Doc}) ->\n\tID = proplists:get_value(<<\"_id\">>, Doc, null),\n\tIDParts = re:split(ID, \"_\"),\n  DocType = lists:nth(1, IDParts),\n\n  case DocType of\n    <<\"page\">> ->\n  \t\tEmit(ID, 1);\n  \t_ ->\n    \tok\n  end\nend."
        },
        "all_tokentypes": {
          "map": "fun({Doc}) ->\n\tID = proplists:get_value(<<\"_id\">>, Doc, null),\n\tIDParts = re:split(ID, \"_\"),\n  DocType = lists:nth(1, IDParts),\n\n  case DocType of\n    <<\"tokentype\">> ->\n  \t\tEmit(ID, 1);\n  \t_ ->\n    \tok\n  end\nend."
        },
        "preload_all_boma_articles": {
          "map": "fun({Doc}) ->\n\tID = proplists:get_value(<<\"_id\">>, Doc, null),\n\tIDParts = re:split(ID, \"_\"),\n  DocType = lists:nth(1, IDParts),\n\n  case DocType of\n    <<\"article\">> ->\n    \tcase proplists:get_value(<<\"data\">>, Doc, null) of\n    \t\t{Data} ->\n    \t\t\tPreload = proplists:get_value(<<\"preload\">>, Data),\n          case Preload of\n          \t1 ->\n          \t  ArticleType = proplists:get_value(<<\"article_type\">>, Data),\n              case ArticleType of\n                <<\"boma_article\">> ->\n                  Emit(ID, 1);\n                <<\"boma_audio_article\">> ->\n                  Emit(ID, 1);\n                <<\"boma_video_article\">> ->\n                  Emit(ID, 1);\n                <<\"boma_news_article\">> ->\n                  Emit(ID, 1);\n                _ ->\n                  ok\n                end;\n        \t\t_ ->\n    \t\t\t\t\tok\n    \t\t\tend;\n    \t\t_ ->\n    \t\t\tok\n    \tend;\n  \t_ ->\n    \tok\n  end\nend."
        }
      }
    }

    couch_update_or_create_design_doc(doc)

    # festival level views

    doc = {
      "_id" => "_design/#{self.name.parameterize.underscore}_#{self.id}_by_model_name_erlang",
      "language" => "erlang",
      "views" => {
        "preload_festival": {
          "map": "fun({Doc}) ->
            ID = proplists:get_value(<<\"_id\">>, Doc, null),
            IDParts = re:split(ID, \"_\"),
            DocType = lists:nth(1, IDParts),

            case proplists:get_value(<<\"data\">>, Doc, null) of
              {Data} ->
                FestivalId = proplists:get_value(<<\"festival_id\">>, Data),
                case FestivalId of
                  #{self.id} ->
                    Preload = proplists:get_value(<<\"preload\">>, Data),
                    case Preload of
                      true ->
                        case DocType of
                          <<\"event\">> ->
                            EventType = proplists:get_value(<<\"event_type\">>, Data),
                              case EventType of
                                <<\"community_event\">> ->
                                  ok;
                                _ ->
                                  Emit(ID, [FestivalId])
                              end;
                          <<\"production\">> ->
                            Emit(ID, [FestivalId]);
                          _ ->
                            ok
                        end;  
                      _ ->
                        case DocType of
                          <<\"venue\">> ->
                            VenueType = proplists:get_value(<<\"venue_type\">>, Data),
                              case VenueType of
                                <<\"performance\">> ->
                                  Emit(ID, [FestivalId]);
                                _ ->
                                  ok
                              end;
                          <<\"tag\">> ->
                            Emit(ID, [FestivalId]);
                          <<\"page\">> ->
                            Emit(ID, [FestivalId]);
                          _ ->
                            ok
                        end
                    end;
                  _ ->
                    ok
                end;
              _ ->
                ok
            end
          end."
        },
        "festival_dump": {
          "map": "fun({Doc}) ->
            ID = proplists:get_value(<<\"_id\">>, Doc, null),
            IDParts = re:split(ID, \"_\"),
            DocType = lists:nth(1, IDParts),

            case proplists:get_value(<<\"data\">>, Doc, null) of
              {Data} ->
                FestivalId = proplists:get_value(<<\"festival_id\">>, Data),
                case FestivalId of
                  #{self.id} ->
                    case DocType of
                      <<\"event\">> ->
                        EventType = proplists:get_value(<<\"event_type\">>, Data),
                        case EventType of
                          {ET} when EventType == <<\"community_event\">> ->
                            ok;
                          _ ->
                            Emit(ID, [FestivalId])
                        end;
                      <<\"production\">> ->
                        Emit(ID, [FestivalId]);
                      <<\"venue\">> ->
                        % VenueType = proplists:get_value(<<\"venue_type\">>, Data),
                        % case VenueType of
                        %  <<\"performance\">> ->
                            Emit(ID, [FestivalId]);
                        %  _ ->
                        %    ok
                        % end;
                      <<\"tag\">> ->
                        Emit(ID, [FestivalId]);
                      <<\"page\">> ->
                        Emit(ID, [FestivalId]);
                      _ ->
                        ok
                    end;
                  _ ->
                    case DocType of
                      <<\"festival\">> ->
                        case ID of
                          <<\"festival_2_#{self.id}\">> ->
                            Emit(ID, [FestivalId]);
                          _ ->
                            ok
                        end;
                      _ ->
                        ok
                    end
                end;
              _ ->
                ok
            end
          end."
        },
        "all_venues": {
          "map": "fun({Doc}) ->
            ID = proplists:get_value(<<\"_id\">>, Doc, null),
            IDParts = re:split(ID, \"_\"),
            DocType = lists:nth(1, IDParts),
          
            case proplists:get_value(<<\"data\">>, Doc, null) of
              {Data} ->
                FestivalId = proplists:get_value(<<\"festival_id\">>, Data),
                case FestivalId of
                  #{self.id} ->
                    case DocType of
                      <<\"venue\">> ->
                        Emit(ID, [FestivalId]);
                      _ ->
                        ok
                    end;
                  _ ->
                    ok
                end;
              _ ->
                ok
            end
          end."     
        },
        "this_festival": {
          "map": "fun({Doc}) ->
            ID = proplists:get_value(<<\"_id\">>, Doc, null),
            IDParts = re:split(ID, \"_\"),
            DocType = lists:nth(1, IDParts),
            DocID = lists:nth(2, IDParts),

            case proplists:get_value(<<\"data\">>, Doc, null) of
              {Data} ->
                FestivalId = proplists:get_value(<<\"festival_id\">>, Data),
                case ID of
                  <<\"festival_2_#{self.id}\">> ->
                    Emit(ID, [FestivalId]);
                  _ ->
                    ok
                end;
              _ ->
                ok
            end
          end."
        },
        "all_pages": {
          "map": "fun({Doc}) ->\n  ID = proplists:get_value(<<\"_id\">>, Doc, null),\n  IDParts = re:split(ID, \"_\"),\n  DocType = lists:nth(1, IDParts),\n\n  case proplists:get_value(<<\"data\">>, Doc, null) of\n    {Data} ->\n      FestivalId = proplists:get_value(<<\"festival_id\">>, Data),\n      case FestivalId of\n        #{self.id} ->\n          case DocType of\n            <<\"page\">> ->\n              \n                  Emit(ID, [FestivalId]);\n\n            _ ->\n              ok\n          end;\n        _ ->\n          ok\n      end;\n    _ ->\n      ok\n  end\nend."
        }
      }
    }

    couch_update_or_create_design_doc doc
  end

  # return the couchdb database name for this festival
  def couchdb_name
    # if using data_structure_version v2
      # couchd is etup to have one database per Organisation
      # the name is the Organisation name underscored concatenated with the festival id
    # if using data_stucture_version v1
      # couchdb is setup to have one database per Festival
      # the name is the festival name underscord concatenated with the festival id
    if self.data_structure_version === 'v2'
      self.organisation.name.parameterize.underscore+"_"+self.organisation.id.to_s
    elsif self.data_structure_version === 'v1'
      self.name.parameterize.underscore+"_"+self.id.to_s
    end
  end
  
  # Return the image_thumb as base64 encoded so that it can be distributed via the 
  # festival couchdb record.  
  def image_thumb
    image = self.image.thumb.url.blank? ? production.image : self.image rescue nil
    unless image.nil? or image.thumb.nil? or image.thumb.url.nil?
      Base64.strict_encode64(image.thumb.read) rescue nil
    end
  end

  def to_couch_data   
    data = {
      name: name,
      start_date: start_date,
      end_date: end_date,
      organisation_id: self.organisation.id,
      couchdb_design_doc_name: self.name.parameterize.underscore+"_"+self.id.to_s,
      aasm_state: aasm_state,
      image_thumb: image_thumb,
      list_order: list_order,
      schedule_modal_type: schedule_modal_type,
      # required for app update nag links on android
      app_bundle_id: self.organisation.bundle_id,
      # required for app udpate nag links on ios
      apple_app_id: self.organisation.apple_app_id,
      current_app_version: self.organisation.current_app_version,
      # datetime when festival mode is enabled
      enable_festival_mode_at: self.enable_festival_mode_at,
      # datetime when festival mode is disabled
      disable_festival_mode_at: self.disable_festival_mode_at,
      # configurable start and end time for clashfinder view
      clashfinder_start_hour: clashfinder_start_hour,
      # used for choosing whether to send activity data from app
      analysis_enabled: analysis_enabled,
      # used for enabling and disabling feedback in the app
      feedback_enabled: feedback_enabled
    }
  end
end
