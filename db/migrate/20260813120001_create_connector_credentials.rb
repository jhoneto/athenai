class CreateConnectorCredentials < ActiveRecord::Migration[8.1]
  def change
    create_table :connector_credentials do |t|
      t.references :connector, null: false, foreign_key: true, index: { unique: true }
      t.text :encrypted_secrets, null: false
      t.datetime :expires_at
      t.timestamps
    end
  end
end
