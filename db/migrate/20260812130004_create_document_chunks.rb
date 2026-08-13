class CreateDocumentChunks < ActiveRecord::Migration[8.1]
  def change
    create_table :document_chunks do |t|
      t.references :document, null: false, foreign_key: true
      t.integer :position, null: false
      t.text    :content, null: false
      t.vector  :embedding, limit: 1536
      t.timestamps
    end

    add_index :document_chunks, [ :document_id, :position ], unique: true
  end
end
