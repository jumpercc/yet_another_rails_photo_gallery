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

ActiveRecord::Schema.define(version: 20140926184004) do

  create_table "albums", force: true do |t|
    t.string   "name",                          null: false
    t.string   "title",                         null: false
    t.integer  "parent_id"
    t.string   "thumb"
    t.boolean  "folder",        default: false, null: false
    t.boolean  "hidden",        default: false, null: false
    t.string   "password_hash"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "thumb_from"
    t.boolean  "protected",     default: false, null: false
  end

  add_index "albums", ["id"], name: "index_albums_on_id"
  add_index "albums", ["name"], name: "index_albums_on_name"
  add_index "albums", ["parent_id"], name: "index_albums_on_parent_id"

  create_table "image_of_days", force: true do |t|
    t.integer "image_id", null: false
    t.date    "day",      null: false
  end

  add_index "image_of_days", ["day"], name: "index_image_of_days_on_day"
  add_index "image_of_days", ["image_id"], name: "index_image_of_days_on_image_id"

  create_table "images", force: true do |t|
    t.integer  "album_id",          null: false
    t.string   "name",              null: false
    t.string   "title",             null: false
    t.date     "created_at"
    t.datetime "updated_at"
    t.integer  "photographer_id"
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
  end

  add_index "images", ["album_id"], name: "index_images_on_album_id"
  add_index "images", ["created_at"], name: "index_images_on_created_at"
  add_index "images", ["id"], name: "index_images_on_id"

  create_table "images_tags", force: true do |t|
    t.integer "image_id", null: false
    t.integer "tag_id",   null: false
  end

  add_index "images_tags", ["image_id"], name: "index_images_tags_on_image_id"
  add_index "images_tags", ["tag_id", "image_id"], name: "index_images_tags_on_tag_id_and_image_id"

  create_table "photographers", force: true do |t|
    t.string "name"
  end

  create_table "tags", force: true do |t|
    t.string   "tag",        null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tags", ["id"], name: "index_tags_on_id"
  add_index "tags", ["tag"], name: "index_tags_on_tag"

  create_table "users", force: true do |t|
    t.string "name",          null: false
    t.string "password_hash", null: false
    t.string "salt",          null: false
  end

  add_index "users", ["name"], name: "index_users_on_name"

end
