class AddNotNullConstraintToSourcesPaymentType < SolidusSupport::Migration[4.2]
  def change
    reversible do |dir|
      dir.up do
        SolidusBraintree::Source.where(payment_type: nil).
          update_all(payment_type: 'CreditCard')
      end
    end
    change_column_null(:solidus_braintree_sources, :payment_type, false)
  end
end
