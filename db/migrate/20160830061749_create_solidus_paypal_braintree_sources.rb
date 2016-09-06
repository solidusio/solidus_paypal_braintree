class CreateSolidusPaypalBraintreeSources < ActiveRecord::Migration
  def change
    create_table :solidus_paypal_braintree_sources do |t|
      t.string :nonce
      t.string :payment_type
      t.integer :user_id, index: true
      t.references :customer, index: true
      t.references :payment_method, foreign_key: { to_table: :spree_payment_method }, index: { name: 'index_braintree_source_payment_method' }

      t.timestamps null: false
    end
  end
end
