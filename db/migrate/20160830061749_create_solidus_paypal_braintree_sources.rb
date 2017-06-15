class CreateSolidusPaypalBraintreeSources < SolidusSupport::Migration[4.2]
  def change
    create_table :solidus_paypal_braintree_sources do |t|
      t.string :nonce
      t.string :token
      t.string :payment_type
      t.integer :user_id, index: true
      t.references :customer, index: true
      t.references :payment_method, index: true

      t.timestamps null: false
    end

    add_foreign_key :solidus_paypal_braintree_sources, :spree_payment_methods, column: :payment_method_id
  end
end
