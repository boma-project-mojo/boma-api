# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2024_02_26_151313) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_stat_statements"
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", precision: nil, null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activities", force: :cascade do |t|
    t.integer "address_id"
    t.string "activity_type"
    t.integer "notification_id"
    t.string "app_version"
    t.string "timezone"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "festival_id"
    t.json "reported_data"
    t.integer "organisation_id"
    t.index ["address_id", "festival_id", "activity_type"], name: "by_address_festival_and_activity_type"
  end

  create_table "addresses", force: :cascade do |t|
    t.string "address"
    t.string "fcm_token"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "unread_push_notifications", default: 0
    t.string "app_version"
    t.json "settings"
    t.index ["address"], name: "index_addresses_on_address"
  end

  create_table "app_data_address_answers", force: :cascade do |t|
    t.integer "address_id"
    t.integer "question_id"
    t.integer "answer_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "app_data_address_events", force: :cascade do |t|
    t.integer "address_id"
    t.integer "event_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "app_data_address_preferences", force: :cascade do |t|
    t.integer "preferable_id"
    t.string "preferable_type"
    t.integer "address_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "app_data_answers", force: :cascade do |t|
    t.integer "question_id"
    t.string "answer_text"
    t.string "answer_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "app_data_articles", force: :cascade do |t|
    t.integer "organisation_id"
    t.integer "festival_id"
    t.integer "user_id"
    t.string "title"
    t.string "standfirst"
    t.string "content"
    t.datetime "image_last_updated_at", precision: nil
    t.string "image"
    t.string "aasm_state"
    t.string "image_name"
    t.string "external_link"
    t.string "video_url"
    t.string "audio_url"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "article_type"
    t.string "wallet_address"
    t.integer "address_id"
    t.datetime "deleted_at", precision: nil
    t.datetime "image_bundled_at", precision: nil
    t.string "source_id"
    t.json "meta"
    t.boolean "featured"
    t.datetime "published_at", precision: nil
    t.datetime "publish_at", precision: nil
    t.index ["deleted_at"], name: "index_app_data_articles_on_deleted_at"
  end

  create_table "app_data_event_productions", id: :serial, force: :cascade do |t|
    t.integer "event_id"
    t.integer "production_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["event_id"], name: "index_app_data_event_productions_on_event_id"
    t.index ["production_id"], name: "index_app_data_event_productions_on_production_id"
  end

  create_table "app_data_events", id: :serial, force: :cascade do |t|
    t.datetime "start_time", precision: nil
    t.datetime "end_time", precision: nil
    t.integer "venue_id"
    t.string "name"
    t.text "description"
    t.string "image_name"
    t.string "image_name_small"
    t.integer "production_id"
    t.text "couch_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "festival_id"
    t.datetime "deleted_at", precision: nil
    t.string "aasm_state"
    t.string "created_by"
    t.string "image"
    t.datetime "image_last_updated_at", precision: nil
    t.datetime "image_bundled_at", precision: nil
    t.string "event_type"
    t.string "source_id"
    t.string "wallet_address"
    t.string "external_link"
    t.boolean "virtual_event", default: false
    t.boolean "audio_stream", default: false
    t.boolean "private_event", default: false
    t.boolean "featured"
    t.datetime "published_at", precision: nil
    t.string "ticket_link"
    t.index ["created_by"], name: "index_app_data_events_on_created_by"
    t.index ["deleted_at"], name: "index_app_data_events_on_deleted_at"
    t.index ["festival_id"], name: "index_app_data_events_on_festival_id"
  end

  create_table "app_data_pages", id: :serial, force: :cascade do |t|
    t.string "name"
    t.text "content"
    t.string "image_name"
    t.string "couch_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "festival_id"
    t.datetime "deleted_at", precision: nil
    t.string "image"
    t.string "aasm_state"
    t.datetime "image_last_updated_at", precision: nil
    t.datetime "image_bundled_at", precision: nil
    t.integer "order"
    t.string "source_id"
    t.index ["deleted_at"], name: "index_app_data_pages_on_deleted_at"
    t.index ["festival_id"], name: "index_app_data_pages_on_festival_id"
  end

  create_table "app_data_people", id: :serial, force: :cascade do |t|
    t.integer "festival_id"
    t.string "email"
    t.string "firstname"
    t.string "surname"
    t.string "company"
    t.string "job_title"
    t.string "aasm_state"
    t.datetime "deleted_at", precision: nil
    t.index ["deleted_at"], name: "index_app_data_people_on_deleted_at"
  end

  create_table "app_data_productions", id: :serial, force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "image_name"
    t.string "couch_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "festival_id"
    t.string "external_link"
    t.string "video_link"
    t.string "short_description", default: ""
    t.string "image"
    t.datetime "deleted_at", precision: nil
    t.string "aasm_state"
    t.string "created_by"
    t.datetime "image_last_updated_at", precision: nil
    t.datetime "image_bundled_at", precision: nil
    t.string "image_fingerprint"
    t.string "source_id"
    t.string "ticket_link"
    t.boolean "preload"
    t.json "meta"
    t.index ["created_by"], name: "index_app_data_productions_on_created_by"
    t.index ["deleted_at"], name: "index_app_data_productions_on_deleted_at"
    t.index ["festival_id"], name: "index_app_data_productions_on_festival_id"
  end

  create_table "app_data_questions", force: :cascade do |t|
    t.integer "survey_id"
    t.string "question_text"
    t.string "question_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "app_data_surveys", force: :cascade do |t|
    t.string "name"
    t.integer "surveyable_id"
    t.string "surveyable_type"
    t.datetime "enable_at"
    t.datetime "disable_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "app_data_taggings", id: false, force: :cascade do |t|
    t.integer "taggable_id", null: false
    t.integer "tag_id", null: false
    t.string "taggable_type", default: "AppData::Production"
  end

  create_table "app_data_tags", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "couch_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "festival_id"
    t.datetime "deleted_at", precision: nil
    t.string "aasm_state"
    t.string "tag_type"
    t.string "source_id"
    t.string "description"
    t.integer "organisation_id"
    t.index ["deleted_at"], name: "index_app_data_tags_on_deleted_at"
    t.index ["festival_id"], name: "index_app_data_tags_on_festival_id"
  end

  create_table "app_data_uploads", force: :cascade do |t|
    t.string "upload_type"
    t.string "aasm_state"
    t.string "processed_url"
    t.string "original_url"
    t.string "uploadable_id"
    t.string "uploadable_type"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "app_data_venues", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "lat"
    t.string "long"
    t.string "image_name"
    t.string "image_name_small"
    t.string "venue_type"
    t.text "description"
    t.string "couch_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "festival_id"
    t.datetime "deleted_at", precision: nil
    t.string "image"
    t.string "aasm_state"
    t.text "menu", default: "<p></p>"
    t.json "dietary_requirements"
    t.datetime "image_last_updated_at", precision: nil
    t.datetime "image_bundled_at", precision: nil
    t.integer "list_order"
    t.string "image_fingerprint"
    t.string "address"
    t.string "osm_id"
    t.string "source_id"
    t.string "wallet_address"
    t.string "external_map_link"
    t.string "city"
    t.string "postcode"
    t.string "address_line_1"
    t.string "address_line_2"
    t.boolean "include_in_clashfinder", default: true
    t.boolean "allow_concurrent_events"
    t.string "subtitle"
    t.index ["deleted_at"], name: "index_app_data_venues_on_deleted_at"
    t.index ["festival_id"], name: "index_app_data_venues_on_festival_id"
  end

  create_table "festivals", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "start_date", precision: nil
    t.datetime "end_date", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "image"
    t.string "fcm_topic_id"
    t.boolean "community_events_enabled"
    t.string "timezone"
    t.boolean "use_production_name_for_event_name", default: true
    t.string "center_lat"
    t.string "center_long"
    t.string "location_radius"
    t.string "organisation_id"
    t.boolean "community_articles_enabled"
    t.string "telegram_stats_chat_id"
    t.string "telegram_moderators_chat_id"
    t.string "bundle_id"
    t.boolean "analysis_enabled"
    t.string "aasm_state"
    t.string "data_structure_version", default: "v2"
    t.string "short_time_format", default: "%a %H:%M"
    t.float "total_images_filesize", default: 0.0
    t.integer "list_order"
    t.string "schedule_modal_type"
    t.boolean "require_production_images", default: true
    t.boolean "require_venue_images", default: true
    t.datetime "enable_festival_mode_at", precision: nil
    t.datetime "disable_festival_mode_at", precision: nil
    t.integer "clashfinder_start_hour", default: 5
    t.boolean "require_description", default: true
    t.boolean "feedback_enabled", default: true
  end

  create_table "messages", id: :serial, force: :cascade do |t|
    t.string "subject"
    t.string "body"
    t.string "topic"
    t.string "pushed_state"
    t.string "sound"
    t.datetime "sent_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "created_by"
    t.datetime "deleted_at", precision: nil
    t.string "festival_id"
    t.integer "article_id"
    t.string "stream"
    t.integer "event_id"
    t.integer "token_type_id"
    t.string "app_version"
    t.datetime "send_at", precision: nil
    t.integer "address_id"
    t.index ["deleted_at"], name: "index_messages_on_deleted_at"
    t.index ["festival_id"], name: "index_messages_on_festival_id"
  end

  create_table "organisation_addresses", force: :cascade do |t|
    t.integer "address_id"
    t.integer "organisation_id"
    t.json "settings"
    t.integer "unread_push_notifications"
    t.string "app_version"
    t.string "fcm_token"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.string "registration_type"
    t.string "registration_id"
    t.json "device_details"
    t.index ["deleted_at"], name: "index_organisation_addresses_on_deleted_at"
    t.index ["organisation_id"], name: "index_organisation_addresses_on_organisation_id"
  end

  create_table "organisations", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "community_articles_enabled", default: false
    t.string "bundle_id"
    t.string "current_app_version"
    t.string "apple_app_id"
    t.boolean "send_data_notifications", default: true
    t.integer "address_nonce"
    t.string "slack_channel_name"
  end

  create_table "push_notifications", force: :cascade do |t|
    t.string "subject"
    t.string "body"
    t.string "pushed_state"
    t.integer "festival_id"
    t.integer "address_id"
    t.string "messagable_type"
    t.integer "messagable_id"
    t.datetime "deleted_at", precision: nil
    t.string "topic_id"
    t.string "notification_type"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "stream"
    t.string "push_error"
    t.integer "unread_push_notifications"
    t.string "registration_type"
    t.string "registration_id"
    t.integer "organisation_id"
    t.integer "message_id"
    t.index ["address_id"], name: "index_push_notifications_on_address_id"
    t.index ["created_at", "festival_id"], name: "index_push_notifications_on_created_at_and_festival_id"
    t.index ["messagable_id", "body"], name: "index_push_notifications_on_messagable_id_and_body"
  end

  create_table "roles", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "resource_type"
    t.integer "resource_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id"
    t.index ["resource_type", "resource_id"], name: "index_roles_on_resource_type_and_resource_id"
  end

  create_table "stats_caches", force: :cascade do |t|
    t.string "period_length"
    t.integer "festival_id"
    t.jsonb "period_data"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "suggestions", id: :serial, force: :cascade do |t|
    t.text "suggestion"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "festival_id"
    t.index ["festival_id"], name: "index_suggestions_on_festival_id"
  end

  create_table "token_types", id: :serial, force: :cascade do |t|
    t.string "contract_address"
    t.string "festival_id"
    t.string "name"
    t.string "image_base64"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "organisation_id"
    t.boolean "is_public", default: false
    t.string "chain"
  end

  create_table "tokens", id: :serial, force: :cascade do |t|
    t.string "festival_id"
    t.string "address"
    t.boolean "was_validated", default: false
    t.string "eth_transaction"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "name"
    t.string "image_base64"
    t.string "token_type_id"
    t.string "aasm_state"
    t.string "token_hash"
    t.integer "transaction_nonce"
    t.index ["festival_id"], name: "index_tokens_on_festival_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "name"
    t.string "confirmation_token"
    t.datetime "confirmed_at", precision: nil
    t.datetime "confirmation_sent_at", precision: nil
    t.string "unconfirmed_email"
    t.integer "role"
    t.string "authentication_token"
    t.string "aasm_state"
    t.datetime "deleted_at", precision: nil
    t.integer "failed_attempts", default: 0
    t.string "unlock_token"
    t.datetime "locked_at", precision: nil
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "users_roles", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "role_id"
    t.index ["role_id"], name: "index_users_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id"
    t.index ["user_id"], name: "index_users_roles_on_user_id"
  end

  create_table "versions", id: :serial, force: :cascade do |t|
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at", precision: nil
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
end
