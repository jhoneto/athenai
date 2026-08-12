class CreateLlmModels < ActiveRecord::Migration[8.1]
  def change
    create_table :llm_models do |t|
      t.string   :model_id, null: false
      t.string   :name, null: false
      t.string   :provider, null: false
      t.string   :family
      t.datetime :model_created_at
      t.integer  :context_window
      t.integer  :max_output_tokens
      t.date     :knowledge_cutoff
      t.jsonb    :modalities, null: false, default: {}
      t.jsonb    :capabilities, null: false, default: []
      t.jsonb    :pricing, null: false, default: {}
      t.jsonb    :metadata, null: false, default: {}
      t.boolean  :enabled, null: false, default: true
      t.timestamps

      t.index [ :provider, :model_id ], unique: true
      t.index :provider
    end
  end
end
