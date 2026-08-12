class CreateAgents < ActiveRecord::Migration[8.1]
  def change
    create_table :agents do |t|
      t.references :account, null: false, foreign_key: true
      t.references :llm_profile, foreign_key: true
      t.string  :name, null: false
      t.text    :description
      t.text    :system_prompt, null: false, default: ""
      t.float   :temperature, null: false, default: 0.7
      t.integer :status, null: false, default: 0
      t.timestamps

      t.index [ :account_id, :name ], unique: true
    end
  end
end
