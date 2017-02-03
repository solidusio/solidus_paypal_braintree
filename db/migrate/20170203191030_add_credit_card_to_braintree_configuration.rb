class AddCreditCardToBraintreeConfiguration < ActiveRecord::Migration
  def change
    add_column :solidus_paypal_braintree_configurations, :credit_card,
      :boolean, null: false, default: false
  end
end
