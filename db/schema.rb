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

ActiveRecord::Schema.define(version: 20160518214153) do

  create_table "audits", force: :cascade do |t|
    t.string   "vendor"
    t.string   "community"
    t.string   "lot"
    t.string   "task"
    t.string   "builder"
    t.datetime "posted"
    t.string   "ready"
    t.string   "completed"
    t.string   "clean"
    t.string   "quality"
    t.string   "started"
    t.text     "note"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.datetime "revised_start"
    t.datetime "revised_end"
    t.datetime "actual_start"
    t.datetime "actual_end"
    t.string   "location"
  end

  create_table "images", force: :cascade do |t|
    t.integer  "audit_id"
    t.string   "file"
    t.string   "filename"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "images", ["audit_id"], name: "index_images_on_audit_id"

end
