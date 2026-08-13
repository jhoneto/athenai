class CreateDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :documents do |t|
      t.references :knowledge_base, null: false, foreign_key: true
      t.string  :filename, null: false
      t.integer :status, null: false, default: 0
      t.text    :error
      t.timestamps
    end
  end
end
