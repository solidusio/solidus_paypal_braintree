class AddCreditCardFieldsToSources < SolidusSupport::Migration[4.2]
  def change
    add_column :solidus_paypal_braintree_sources, :cc_type, :string
    add_column :solidus_paypal_braintree_sources, :last_digits, :string
  end
end
