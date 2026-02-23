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

ActiveRecord::Schema[8.1].define(version: 2026_02_23_201544) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "golfers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "sportsdata_id"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_golfers_on_name"
    t.index ["sportsdata_id"], name: "index_golfers_on_sportsdata_id", unique: true
  end

  create_table "picks", force: :cascade do |t|
    t.boolean "auto_assigned", default: false, null: false
    t.datetime "created_at", null: false
    t.bigint "earnings_cents"
    t.bigint "golfer_id", null: false
    t.boolean "is_double_down", default: false, null: false
    t.boolean "made_cut"
    t.bigint "tournament_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["golfer_id"], name: "index_picks_on_golfer_id"
    t.index ["tournament_id"], name: "index_picks_on_tournament_id"
    t.index ["user_id", "golfer_id"], name: "index_picks_on_user_id_and_golfer_id", unique: true
    t.index ["user_id", "tournament_id"], name: "index_picks_on_user_id_and_tournament_id", unique: true
    t.index ["user_id"], name: "index_picks_on_user_id"
  end

  create_table "tournament_entries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "golfer_id", null: false
    t.bigint "tournament_id", null: false
    t.datetime "updated_at", null: false
    t.index ["golfer_id"], name: "index_tournament_entries_on_golfer_id"
    t.index ["tournament_id", "golfer_id"], name: "index_tournament_entries_on_tournament_id_and_golfer_id", unique: true
    t.index ["tournament_id"], name: "index_tournament_entries_on_tournament_id"
  end

  create_table "tournament_results", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "current_earnings_cents"
    t.integer "current_position"
    t.string "current_position_display"
    t.integer "current_round"
    t.integer "current_score_to_par"
    t.string "current_thru"
    t.bigint "earnings_cents", default: 0
    t.bigint "golfer_id", null: false
    t.boolean "made_cut", default: false, null: false
    t.integer "position"
    t.bigint "tournament_id", null: false
    t.datetime "updated_at", null: false
    t.index ["golfer_id"], name: "index_tournament_results_on_golfer_id"
    t.index ["tournament_id", "golfer_id"], name: "index_tournament_results_on_tournament_id_and_golfer_id", unique: true
    t.index ["tournament_id"], name: "index_tournament_results_on_tournament_id"
  end

  create_table "tournaments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "end_date"
    t.string "name", null: false
    t.string "pgatour_id"
    t.datetime "picks_locked_at"
    t.bigint "purse_cents", default: 0
    t.string "sportsdata_id"
    t.date "start_date"
    t.string "status", default: "upcoming", null: false
    t.string "tournament_type", default: "regular", null: false
    t.datetime "updated_at", null: false
    t.integer "week_number"
    t.index ["sportsdata_id"], name: "index_tournaments_on_sportsdata_id", unique: true
    t.index ["start_date"], name: "index_tournaments_on_start_date"
    t.index ["week_number"], name: "index_tournaments_on_week_number", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.boolean "approved", default: false, null: false
    t.datetime "created_at", null: false
    t.integer "double_downs_remaining", default: 5, null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.boolean "entry_paid", default: false, null: false
    t.string "name", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "picks", "golfers"
  add_foreign_key "picks", "tournaments"
  add_foreign_key "picks", "users"
  add_foreign_key "tournament_entries", "golfers"
  add_foreign_key "tournament_entries", "tournaments"
  add_foreign_key "tournament_results", "golfers"
  add_foreign_key "tournament_results", "tournaments"
end
