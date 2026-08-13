class CreateKnowledgeBases < ActiveRecord::Migration[8.1]
  def change
    create_table :knowledge_bases do |t|
      t.references :agent, null: false, foreign_key: true, index: { unique: true }
      t.timestamps
    end
  end
end
