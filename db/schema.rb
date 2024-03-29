# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150117220330) do

  create_table "acts", force: true do |t|
    t.string   "name"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "echonest_id"
  end

  create_table "acts_shows", id: false, force: true do |t|
    t.integer "show_id"
    t.integer "act_id"
  end

  create_table "boards", force: true do |t|
    t.string   "name"
    t.string   "state",                     default: "private", null: false
    t.string   "vanity_url"
    t.string   "email"
    t.string   "phone"
    t.integer  "paid_tier",                 default: 0,         null: false
    t.datetime "paid_at"
    t.string   "referral_code"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "timezone"
    t.string   "header_image_file_name"
    t.string   "header_image_content_type"
    t.integer  "header_image_file_size"
    t.datetime "header_image_updated_at"
  end

  create_table "cards", force: true do |t|
    t.date     "expiration"
    t.string   "brand"
    t.string   "last4"
    t.string   "stripe_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "state"
    t.string   "error"
    t.string   "stripe_token"
    t.string   "guid"
  end

  create_table "carts", force: true do |t|
    t.string   "reserve_code", default: ""
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "carts_tickets", id: false, force: true do |t|
    t.integer "cart_id"
    t.integer "ticket_id"
  end

  create_table "charges", force: true do |t|
    t.integer  "sale_id"
    t.string   "stripe_id"
    t.integer  "actionee_id"
    t.string   "actionee_type"
    t.integer  "actioner_id"
    t.string   "actioner_type"
    t.integer  "amount",          default: 0
    t.string   "state",           default: "charged"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "application_fee"
    t.integer  "am_base"
    t.integer  "am_charity"
    t.integer  "am_sb"
  end

  create_table "email_subscriptions", force: true do |t|
    t.integer  "email_subscriber_id"
    t.string   "email_subscriber_type"
    t.integer  "board_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email"
  end

  create_table "ext_links", force: true do |t|
    t.string   "url"
    t.string   "ext_site"
    t.integer  "linkable_id"
    t.string   "linkable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "guests", force: true do |t|
    t.string   "email"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "stripe_id"
  end

  add_index "guests", ["email"], name: "index_guests_on_email", unique: true

  create_table "places", force: true do |t|
    t.string   "formatted_address"
    t.string   "formatted_phone_number"
    t.float    "lat"
    t.float    "lng"
    t.string   "international_phone_number"
    t.string   "name"
    t.text     "opening_hours"
    t.string   "photo1"
    t.string   "photo2"
    t.string   "photo3"
    t.string   "photo4"
    t.string   "photo5"
    t.integer  "price_level"
    t.float    "rating"
    t.integer  "utc_offset"
    t.string   "vicinity"
    t.string   "website"
    t.text     "reference",                  limit: 255
    t.integer  "stage_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "places", ["stage_id"], name: "index_places_on_stage_id"

  create_table "sales", force: true do |t|
    t.integer  "actioner_id"
    t.string   "actioner_type"
    t.integer  "actionee_id"
    t.string   "actionee_type"
    t.text     "error"
    t.string   "stripe_token"
    t.integer  "amount_base"
    t.integer  "amount_tip"
    t.integer  "amount_sb"
    t.integer  "amount_charity"
    t.integer  "coupon_id"
    t.integer  "affiliate_id"
    t.string   "guid"
    t.string   "state"
    t.string   "plan"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "stripe_remember_card"
    t.decimal  "am_base",              precision: 8, scale: 2
    t.decimal  "am_added",             precision: 8, scale: 2
    t.decimal  "am_product",           precision: 8, scale: 2
    t.decimal  "am_tip",               precision: 8, scale: 2
    t.decimal  "am_sb",                precision: 8, scale: 2
    t.decimal  "am_charity",           precision: 8, scale: 2
    t.boolean  "email_subscribe",                              default: false
  end

  create_table "shows", force: true do |t|
    t.integer  "board_id"
    t.integer  "stage_id"
    t.string   "state"
    t.string   "error"
    t.datetime "announce_at"
    t.datetime "door_at"
    t.datetime "show_at"
    t.decimal  "price_adv",       precision: 8, scale: 2
    t.decimal  "price_door",      precision: 8, scale: 2
    t.boolean  "pwyw",                                    default: false,      null: false
    t.string   "ticketing_type",                          default: "none"
    t.integer  "custom_capacity"
    t.integer  "payer_id"
    t.datetime "paid_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "min_age",                                 default: "All ages"
    t.string   "title"
    t.string   "category",                                default: ""
  end

  create_table "stages", force: true do |t|
    t.string   "name"
    t.integer  "board_id"
    t.integer  "capacity"
    t.text     "places_reference",               limit: 255
    t.string   "places_formatted_address_short"
    t.text     "places_json"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "stripe_events", force: true do |t|
    t.string   "stripe_id"
    t.string   "stripe_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "subscriptions", force: true do |t|
    t.integer  "sale_id"
    t.string   "stripe_id"
    t.integer  "board_id"
    t.integer  "amount"
    t.string   "plan"
    t.string   "state"
    t.integer  "user_id"
    t.datetime "paid_until"
    t.datetime "paid_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tickets", force: true do |t|
    t.string   "token"
    t.integer  "ticket_owner_id"
    t.string   "ticket_owner_type"
    t.integer  "show_id"
    t.string   "state",                                     default: "open"
    t.string   "tier"
    t.string   "seat"
    t.string   "buy_method"
    t.string   "claim_method"
    t.decimal  "price",             precision: 8, scale: 2
    t.integer  "referral_band_id"
    t.datetime "reserved_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "guid"
  end

  add_index "tickets", ["referral_band_id"], name: "index_tickets_on_referral_band_id"
  add_index "tickets", ["show_id"], name: "index_tickets_on_show_id"

  create_table "user_boards", force: true do |t|
    t.integer  "boarder_id"
    t.integer  "board_id"
    t.string   "role",       default: "", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_boards", ["board_id", "role"], name: "index_user_boards_on_board_id_and_role"
  add_index "user_boards", ["board_id"], name: "index_user_boards_on_board_id"
  add_index "user_boards", ["boarder_id", "board_id"], name: "index_user_boards_on_boarder_id_and_board_id", unique: true
  add_index "user_boards", ["boarder_id"], name: "index_user_boards_on_boarder_id"

  create_table "users", force: true do |t|
    t.string   "email",                  default: "",    null: false
    t.string   "encrypted_password",     default: "",    null: false
    t.boolean  "admin",                  default: false, null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.string   "stripe_id"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "provider"
    t.string   "facebook_uid"
    t.string   "facebook_nickname"
    t.string   "facebook_email"
    t.string   "facebook_image"
    t.string   "facebook_location"
    t.string   "facebook_url"
    t.integer  "timezone"
    t.string   "stripe_scope"
    t.boolean  "stripe_livemode"
    t.string   "stripe_publishable_key"
    t.string   "stripe_token"
    t.string   "stripe_token_type"
    t.string   "stripe_recipient_id"
    t.string   "stripe_recipient_email"
    t.string   "reserve_code"
    t.string   "stripe_access_key"
    t.string   "stripe_default_card"
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true

  create_table "versions", force: true do |t|
    t.string   "item_type",      null: false
    t.integer  "item_id",        null: false
    t.string   "event",          null: false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
    t.text     "object_changes"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"

end
