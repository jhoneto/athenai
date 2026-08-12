class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.references :session, null: false, foreign_key: true
      t.references :llm_model, foreign_key: true
      t.integer :role, null: false
      t.text    :content
      t.jsonb   :content_raw, default: {}
      t.text    :thinking_text
      t.text    :thinking_signature
      t.integer :thinking_tokens
      t.integer :input_tokens
      t.integer :output_tokens
      t.integer :cached_tokens
      t.integer :cache_creation_tokens
      t.timestamps

      t.index [ :session_id, :created_at ]
    end
  end
end
