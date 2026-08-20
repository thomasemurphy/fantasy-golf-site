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

ActiveRecord::Schema[8.1].define(version: 2026_08_20_154528) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_stat_statements"

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
    t.index ["user_id", "golfer_id"], name: "index_picks_on_user_id_and_golfer_id"
    t.index ["user_id", "tournament_id"], name: "index_picks_on_user_id_and_tournament_id", unique: true
    t.index ["user_id"], name: "index_picks_on_user_id"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "team_pairings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "espn_team_name", null: false
    t.bigint "golfer_a_id", null: false
    t.bigint "golfer_b_id", null: false
    t.bigint "tournament_id", null: false
    t.datetime "updated_at", null: false
    t.index ["golfer_a_id"], name: "index_team_pairings_on_golfer_a_id"
    t.index ["golfer_b_id"], name: "index_team_pairings_on_golfer_b_id"
    t.index ["tournament_id", "espn_team_name"], name: "index_team_pairings_on_tournament_id_and_espn_team_name", unique: true
    t.index ["tournament_id"], name: "index_team_pairings_on_tournament_id"
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
    t.bigint "earnings_cents"
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
    t.string "city"
    t.string "course_name"
    t.datetime "created_at", null: false
    t.date "end_date"
    t.boolean "is_team_event", default: false, null: false
    t.string "name", null: false
    t.boolean "no_cut", default: false, null: false
    t.string "pgatour_id"
    t.datetime "picks_locked_at"
    t.bigint "purse_cents", default: 0
    t.string "sportsdata_id"
    t.date "start_date"
    t.string "state"
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
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "team_pairings", "golfers", column: "golfer_a_id"
  add_foreign_key "team_pairings", "golfers", column: "golfer_b_id"
  add_foreign_key "team_pairings", "tournaments"
  add_foreign_key "tournament_entries", "golfers"
  add_foreign_key "tournament_entries", "tournaments"
  add_foreign_key "tournament_results", "golfers"
  add_foreign_key "tournament_results", "tournaments"
end
