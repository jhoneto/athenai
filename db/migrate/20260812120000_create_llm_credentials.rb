class CreateLlmCredentials < ActiveRecord::Migration[8.1]
  def change
    create_table :llm_credentials do |t|
      t.references :account, null: false, foreign_key: true
      t.integer :provider, null: false
      t.text    :encrypted_api_key, null: false
      t.timestamps
    end

    add_index :llm_credentials, [ :account_id, :provider ], unique: true
  end
end
