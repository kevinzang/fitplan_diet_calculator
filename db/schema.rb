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

ActiveRecord::Schema.define(version: 20140414194455) do

  create_table "food_entries", force: true do |t|
    t.string   "username"
    t.string   "food"
    t.integer  "calories"
    t.string   "date"
    t.string   "serving"
    t.integer  "numservings"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "food_searches", force: true do |t|
    t.integer  "num"
    t.string   "link"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "searched"
    t.string   "food"
    t.string   "date"
    t.string   "serving"
    t.string   "calories"
  end

  create_table "user_profiles", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "username"
    t.string   "password"
    t.integer  "height"
    t.integer  "weight"
    t.integer  "desired_weight"
    t.integer  "age"
    t.string   "gender"
    t.string   "remember_token"
    t.integer  "activity_level"
    t.float    "weight_change_per_week_goal"
  end

  add_index "user_profiles", ["remember_token"], name: "index_user_profiles_on_remember_token"

  create_table "weight_entries", force: true do |t|
    t.string   "username"
    t.string   "date"
    t.integer  "weight"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
