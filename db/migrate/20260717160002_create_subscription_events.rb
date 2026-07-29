class CreateSubscriptionEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :subscription_events do |t|
      t.references :subscription, null: false, foreign_key: true
      t.string :event_type,       null: false
      t.string :stripe_event_id
      t.jsonb  :payload,          null: false, default: {}
      t.timestamps
    end

    add_index :subscription_events, :stripe_event_id, unique: true,
              where: "stripe_event_id IS NOT NULL"
  end
end
