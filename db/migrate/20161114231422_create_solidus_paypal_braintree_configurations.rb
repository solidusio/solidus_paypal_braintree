class CreateSolidusPaypalBraintreeConfigurations < SolidusSupport::Migration[4.2]
  def change
    create_table :solidus_paypal_braintree_configurations do |t|
      t.boolean :paypal,    null: false, default: false
      t.boolean :apple_pay, null: false, default: false
      t.integer :store_id,  null: false, index: true, foreign_key: { references: :spree_stores }

      t.timestamps null: false
    end
  end
end
