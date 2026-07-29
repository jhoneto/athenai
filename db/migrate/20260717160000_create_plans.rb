class CreatePlans < ActiveRecord::Migration[8.1]
  def change
    create_table :plans do |t|
      t.string  :name,               null: false
      t.string  :slug,               null: false
      t.string  :stripe_price_id
      t.integer :analyses_per_month
      t.integer :price_cents,        null: false, default: 0
      t.boolean :active,             null: false, default: true
      t.timestamps
    end

    add_index :plans, :slug, unique: true
    add_index :plans, :stripe_price_id, unique: true, where: "stripe_price_id IS NOT NULL"
  end
end
