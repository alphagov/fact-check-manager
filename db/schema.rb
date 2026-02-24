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

ActiveRecord::Schema[8.0].define(version: 2026_02_24_092134) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "collaborations", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "request_id"
    t.string "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["request_id"], name: "index_collaborations_on_request_id"
    t.index ["user_id", "request_id"], name: "index_collaborations_on_user_id_and_request_id", unique: true
    t.index ["user_id"], name: "index_collaborations_on_user_id"
  end

  create_table "requests", force: :cascade do |t|
    t.uuid "source_id", null: false
    t.string "requester_name", null: false
    t.string "requester_email", null: false
    t.string "status", default: "new", null: false
    t.datetime "deadline", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "source_app", null: false
    t.string "source_url"
    t.string "source_title"
    t.json "current_content", null: false
    t.json "previous_content"
    t.index ["created_at"], name: "index_requests_on_created_at"
    t.index ["source_id"], name: "index_requests_on_source_id"
  end

  create_table "responses", force: :cascade do |t|
    t.bigint "request_id", null: false
    t.bigint "user_id", null: false
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["request_id"], name: "index_responses_on_request_id", unique: true
    t.index ["user_id"], name: "index_responses_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "uid"
    t.string "organisation_slug"
    t.string "organisation_content_id"
    t.string "app_name"
    t.text "permissions", default: [], array: true
    t.boolean "remotely_signed_out", default: false
    t.boolean "disabled", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_users_on_uid", unique: true
  end

  add_foreign_key "responses", "requests"
  add_foreign_key "responses", "users"
end
