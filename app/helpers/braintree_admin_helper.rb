module BraintreeAdminHelper
  # Returns a link to the Braintree web UI for the given Braintree payment
  def braintree_transaction_link(payment)
    environment = payment.payment_method.preferred_environment == 'sandbox' ? 'sandbox' : 'www'
    merchant_id = payment.payment_method.preferred_merchant_id
    response_code = payment.response_code

    return unless response_code.present?
    return response_code unless merchant_id.present?

    link_to(
      response_code,
      "https://#{environment}.braintreegateway.com/merchants/#{merchant_id}/transactions/#{response_code}",
      title: 'Show payment on Braintree',
      target: '_blank'
    )
  end
end
