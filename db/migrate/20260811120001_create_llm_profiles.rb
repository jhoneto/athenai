class CreateLlmProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :llm_profiles do |t|
      t.integer :key, null: false
      t.string  :name, null: false
      t.references :llm_model, foreign_key: { to_table: :llm_models }
      t.decimal :credit_multiplier, precision: 6, scale: 2, null: false
      t.boolean :active, null: false, default: true
      t.timestamps

      t.index :key, unique: true
    end
  end
end
