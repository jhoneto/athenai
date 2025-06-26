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

ActiveRecord::Schema[8.0].define(version: 2025_06_26_003852) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "agent_functions", force: :cascade do |t|
    t.bigint "agent_id", null: false
    t.bigint "function_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_id", "function_id"], name: "index_agent_functions_on_agent_id_and_function_id", unique: true
    t.index ["agent_id"], name: "index_agent_functions_on_agent_id"
    t.index ["function_id"], name: "index_agent_functions_on_function_id"
  end

  create_table "agents", force: :cascade do |t|
    t.string "name"
    t.text "prompt"
    t.bigint "workspace_id", null: false
    t.bigint "llm_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["llm_id"], name: "index_agents_on_llm_id"
    t.index ["workspace_id"], name: "index_agents_on_workspace_id"
  end

  create_table "functions", force: :cascade do |t|
    t.string "name"
    t.text "code"
    t.bigint "workspace_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["workspace_id"], name: "index_functions_on_workspace_id"
  end

  create_table "llms", force: :cascade do |t|
    t.string "name"
    t.string "provider"
    t.string "model"
    t.text "configs"
    t.bigint "workspace_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["workspace_id"], name: "index_llms_on_workspace_id"
  end

  create_table "user_workspaces", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "workspace_id", null: false
    t.boolean "access_llm"
    t.boolean "access_agents"
    t.boolean "access_functions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_workspaces_on_user_id"
    t.index ["workspace_id"], name: "index_user_workspaces_on_workspace_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "workspaces", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_workspaces_on_user_id"
  end

  add_foreign_key "agent_functions", "agents"
  add_foreign_key "agent_functions", "functions"
  add_foreign_key "agents", "llms"
  add_foreign_key "agents", "workspaces"
  add_foreign_key "functions", "workspaces"
  add_foreign_key "llms", "workspaces"
  add_foreign_key "user_workspaces", "users"
  add_foreign_key "user_workspaces", "workspaces"
  add_foreign_key "workspaces", "users"
end
