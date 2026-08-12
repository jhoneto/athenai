class CreateSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions do |t|
      t.references :account, null: false, foreign_key: true
      t.references :agent, null: false, foreign_key: true
      t.references :llm_profile, null: false, foreign_key: true
      t.references :llm_model, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string  :title
      t.integer :status, null: false, default: 0
      t.timestamps
    end
  end
end
