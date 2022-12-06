# frozen_string_literal: true

module SolidusBraintree
  module BraintreeAdminHelper
    # Returns a link to the Braintree web UI for the given Braintree payment
    def braintree_transaction_link(payment)
      environment = payment.payment_method.preferred_environment == 'sandbox' ? 'sandbox' : 'www'
      merchant_id = payment.payment_method.preferred_merchant_id
      response_code = payment.response_code

      return if response_code.blank?
      return response_code if merchant_id.blank?

      link_to(
        response_code,
        "https://#{environment}.braintreegateway.com/merchants/#{merchant_id}/transactions/#{response_code}",
        title: 'Show payment on Braintree',
        target: '_blank',
        rel: 'noopener'
      )
    end
  end
end
