class AddNullConstraintToSources < SolidusSupport::Migration[4.2]
  def up
    payments = Spree::Payment.arel_table
    sources = SolidusPaypalBraintree::Source.arel_table
    join_sources = payments.join(sources).on(
      payments[:source_id].eq(sources[:id]).and(
        payments[:source_type].eq("SolidusPaypalBraintree::Source")
      ).and(
        sources[:payment_method_id].eq(nil)
      )
    ).join_sources

    count = Spree::Payment.joins(join_sources).count
    Rails.logger.info("Updating #{count} problematic sources")

    Spree::Payment.joins(join_sources).find_each do |payment|
      Rails.logger.info("Updating source #{payment.source_id} with payment method id #{payment.payment_method_id}")
      SolidusPaypalBraintree::Source.where(id: payment.source_id).update_all(payment_method_id: payment.payment_method_id)
    end

    # We use a foreign key constraint on the model,
    # but it doesnt make sense to have this model exist without a payment method
    # as two of its methods delegate to the payment method.
    change_column_null(:solidus_paypal_braintree_sources, :payment_method_id, false)
  end

  def down
    change_column_null(:solidus_paypal_braintree_sources, :payment_method_id, true)
  end
end
