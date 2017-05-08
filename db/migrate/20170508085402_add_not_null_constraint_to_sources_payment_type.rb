class AddNotNullConstraintToSourcesPaymentType < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        SolidusPaypalBraintree::Source.where(payment_type: nil).
          update_all(payment_type: 'CreditCard')
      end
    end
    change_column_null(:solidus_paypal_braintree_sources, :payment_type, false)
  end
end
