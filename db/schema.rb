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

ActiveRecord::Schema[8.1].define(version: 2026_08_12_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "account_users", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.integer "role", default: 2, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["account_id", "user_id"], name: "index_account_users_on_account_id_and_user_id", unique: true
    t.index ["account_id"], name: "index_account_users_on_account_id"
    t.index ["user_id"], name: "index_account_users_on_user_id"
  end

  create_table "accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "agents", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.bigint "llm_profile_id"
    t.string "name", null: false
    t.integer "status", default: 0, null: false
    t.text "system_prompt", default: "", null: false
    t.float "temperature", default: 0.7, null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "name"], name: "index_agents_on_account_id_and_name", unique: true
    t.index ["account_id"], name: "index_agents_on_account_id"
    t.index ["llm_profile_id"], name: "index_agents_on_llm_profile_id"
  end

  create_table "llm_credentials", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.text "encrypted_api_key", null: false
    t.integer "provider", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "provider"], name: "index_llm_credentials_on_account_id_and_provider", unique: true
    t.index ["account_id"], name: "index_llm_credentials_on_account_id"
  end

  create_table "llm_models", force: :cascade do |t|
    t.jsonb "capabilities", default: [], null: false
    t.integer "context_window"
    t.datetime "created_at", null: false
    t.boolean "enabled", default: true, null: false
    t.string "family"
    t.date "knowledge_cutoff"
    t.integer "max_output_tokens"
    t.jsonb "metadata", default: {}, null: false
    t.jsonb "modalities", default: {}, null: false
    t.datetime "model_created_at"
    t.string "model_id", null: false
    t.string "name", null: false
    t.jsonb "pricing", default: {}, null: false
    t.string "provider", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "model_id"], name: "index_llm_models_on_provider_and_model_id", unique: true
    t.index ["provider"], name: "index_llm_models_on_provider"
  end

  create_table "llm_profiles", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.decimal "credit_multiplier", precision: 6, scale: 2, null: false
    t.integer "key", null: false
    t.bigint "llm_model_id"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_llm_profiles_on_key", unique: true
    t.index ["llm_model_id"], name: "index_llm_profiles_on_llm_model_id"
  end

  create_table "plans", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.integer "analyses_per_month"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "price_cents", default: 0, null: false
    t.string "slug", null: false
    t.string "stripe_price_id"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_plans_on_slug", unique: true
    t.index ["stripe_price_id"], name: "index_plans_on_stripe_price_id", unique: true, where: "(stripe_price_id IS NOT NULL)"
  end

  create_table "subscription_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.jsonb "payload", default: {}, null: false
    t.string "stripe_event_id"
    t.bigint "subscription_id", null: false
    t.datetime "updated_at", null: false
    t.index ["stripe_event_id"], name: "index_subscription_events_on_stripe_event_id", unique: true, where: "(stripe_event_id IS NOT NULL)"
    t.index ["subscription_id"], name: "index_subscription_events_on_subscription_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.integer "analyses_used", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "current_period_end"
    t.datetime "current_period_start"
    t.bigint "plan_id"
    t.integer "status", default: 0, null: false
    t.string "stripe_customer_id"
    t.string "stripe_subscription_id"
    t.integer "trial_analyses_total", default: 5, null: false
    t.integer "trial_analyses_used", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_subscriptions_on_account_id", unique: true
    t.index ["plan_id"], name: "index_subscriptions_on_plan_id"
    t.index ["stripe_subscription_id"], name: "index_subscriptions_on_stripe_subscription_id", unique: true, where: "(stripe_subscription_id IS NOT NULL)"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "account_users", "accounts"
  add_foreign_key "account_users", "users"
  add_foreign_key "agents", "accounts"
  add_foreign_key "agents", "llm_profiles"
  add_foreign_key "llm_credentials", "accounts"
  add_foreign_key "llm_profiles", "llm_models"
  add_foreign_key "subscription_events", "subscriptions"
  add_foreign_key "subscriptions", "accounts"
  add_foreign_key "subscriptions", "plans"
end
