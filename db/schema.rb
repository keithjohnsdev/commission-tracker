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

ActiveRecord::Schema[8.1].define(version: 2026_06_24_150626) do
  create_table "advisors", force: :cascade do |t|
    t.integer "agency_id", null: false
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["agency_id"], name: "index_advisors_on_agency_id"
  end

  create_table "agencies", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "default_commission_rate"
    t.string "iata_number"
    t.string "name"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "advisors", "agencies"
end
