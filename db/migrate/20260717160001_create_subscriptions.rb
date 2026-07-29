class CreateSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriptions do |t|
      t.references :account, null: false, foreign_key: true, index: { unique: true }
      t.references :plan,    foreign_key: true

      t.string  :stripe_subscription_id
      t.string  :stripe_customer_id
      t.integer :status,                  null: false, default: 0
      t.datetime :current_period_start
      t.datetime :current_period_end

      t.integer :analyses_used,        null: false, default: 0
      t.integer :trial_analyses_total, null: false, default: 5
      t.integer :trial_analyses_used,  null: false, default: 0

      t.timestamps
    end

    add_index :subscriptions, :stripe_subscription_id, unique: true,
              where: "stripe_subscription_id IS NOT NULL"
  end
end
